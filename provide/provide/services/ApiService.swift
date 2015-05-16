//
//  ApiService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnSuccess = (statusCode: Int, mappingResult: RKMappingResult!) -> ()
typealias OnError = (error: NSError, statusCode: Int, responseString: String) -> ()

class ApiService: NSObject {

    private let mimeMappings = [
        "image/jpg": "jpg",
        "video/mp4": "m4v"
    ]

    private let objectMappings = [
        "attachments": Attachment.mapping(),
        "companies": Company.mapping(),
        "devices": Device.mapping(),
        "directions": Directions.mapping(),
        "eta": Directions.mapping(),
        "products": Product.mapping(),
        "providers": Provider.mapping(),
        "routes": Route.mapping(),
        "tokens": Token.mapping(),
        "work_orders": WorkOrder.mapping(),
        "users": User.mapping()
    ]

    private var headers = [String : String]()

    class func sharedService() -> ApiService {
        struct Static {
            static let instance = ApiService()
        }
        return Static.instance
    }

    override init() {
        super.init()

        if let token = KeyChainService.sharedService().token {
            headers["X-API-Authorization"] = token.authorizationHeaderString
        }
    }

    // MARK: Token API

    class func hasCachedToken() -> Bool {
        return KeyChainService.sharedService().token != nil
    }

    func login(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("tokens", method: .POST, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            assert(statusCode == 201)
            let token = mappingResult.firstObject as! Token
            self.headers["X-API-Authorization"] = token.authorizationHeaderString
            KeyChainService.sharedService().token = token
            KeyChainService.sharedService().email = params.objectForKey("email") as? String

            self.registerForRemoteNotifications()
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
            KeyChainService.sharedService().clearStoredUserData()
        }
    }

    func logout(onSuccess: OnSuccess, onError: OnError) {

        if let token = KeyChainService.sharedService().token {
            dispatchApiOperationForPath("tokens/\(token.id)", method: .DELETE, params: nil, onSuccess: { (statusCode, mappingResult) -> () in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                self.localLogout()
            }, onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
                self.localLogout()
            })
        }
    }

    private func localLogout() {
        unregisterForRemoteNotifications()
        headers.removeValueForKey("X-API-Authorization")
        KeyChainService.sharedService().clearStoredUserData()
    }

    // MARK: User API
    
    func fetchUser(#onSuccess: OnSuccess, onError: OnError) {
        if let token = KeyChainService.sharedService().token {
            dispatchApiOperationForPath("users/\(token.userId)", method: .GET, params: [:], onSuccess: { (statusCode, mappingResult) -> () in
                assert(statusCode == 200)
                let user = mappingResult.firstObject as! User
                KeyChainService.sharedService().user = user
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            }, onError: { (error, statusCode, responseString) -> () in
                var errorMessage: String
                switch statusCode {
                case 401: errorMessage = "Authorization revoked"
                case 403: errorMessage = "Forbidden"
                default:  errorMessage = "Failed to retrieve user details"
                }

                onError(error: error, statusCode: statusCode, responseString: responseString)
            })
        }
    }

    func updateUser(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        if let token = KeyChainService.sharedService().token {
            dispatchApiOperationForPath("users/\(token.userId)", method: .PUT, params: params, onSuccess: { (statusCode, mappingResult) -> () in
                assert(statusCode == 204)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            }, onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            })
        }
    }

    func addAttachment(data: NSData!, withMimeType mimeType: String!, toUserWithId id: String!, params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("users/\(id)/attachments/new", method: .GET, params: ["filename": "upload.\(mimeMappings[mimeType]!)"],
            onSuccess: { (statusCode, mappingResult) -> () in
                assert(statusCode == 200)
                let attachment = mappingResult.firstObject as? Attachment

                self.uploadToS3(NSURL(string: attachment!.url)!, data: data, withMimeType: mimeType, params: attachment!.fields,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        var realParams = NSMutableDictionary(dictionary: params)
                        realParams.setObject(attachment!.fields.objectForKey("key")!, forKey: "key")
                        realParams.setObject(mimeType, forKey: "mime_type")

                        var url = attachment!.url + (attachment!.fields.objectForKey("key") as! String)
                        realParams.setObject(url, forKey: "url")

                        self.dispatchApiOperationForPath("users/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess,
                            onError: { (error, statusCode, responseString) -> () in
                                onError(error: error, statusCode: statusCode, responseString: responseString)
                            }
                        )
                    }, onError: { (error, statusCode, responseString) -> () in
                        onError(error: error, statusCode: statusCode, responseString: responseString)
                    }
                )
            },
            onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    // MARK: Device API

    func createDevice(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("devices", method: .POST, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            assert(statusCode == 201)
            KeyChainService.sharedService().deviceId = (mappingResult.firstObject as! Device).id.stringValue
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func deleteDeviceWithId(id: String!, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("devices/\(id)", method: .DELETE, params: nil, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    // MARK: Remote notifications
    
    private func registerForRemoteNotifications() {
        if isSimulator() == false {
            let notificationTypes = UIUserNotificationType.Badge | UIUserNotificationType.Sound | UIUserNotificationType.Alert
            let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        }
    }

    private func unregisterForRemoteNotifications() {
        if isSimulator() == false {
            UIApplication.sharedApplication().unregisterForRemoteNotifications()

            if let deviceId = KeyChainService.sharedService().deviceId {
                ApiService.sharedService().deleteDeviceWithId(deviceId, onSuccess: { (statusCode, mappingResult) -> () in

                }, onError: { (error, statusCode, responseString) -> () in

                })
            }
        }
    }

    // MARK: Provider API

    func fetchProviders(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("providers", method: .GET, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func fetchProviderAvailability(id: String!, params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("providers/\(id)/availability", method: .GET, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    // MARK: Checkin API
    
    func checkin(location: CLLocation) {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let checkinDate = dateFormatter.stringFromDate(location.timestamp)
        
        let longitude = location.coordinate.longitude;
        let latitude = location.coordinate.latitude;
        
        let params = ["latitude": latitude, "longitude": longitude, "checkin_at": checkinDate]
        
        checkin(params, onSuccess: { (statusCode, mappingResult) -> () in

        }) { (error, statusCode, responseString) -> () in

        }
    }
    
    func checkin(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("checkins", method: .POST, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            assert(statusCode == 201)
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    // MARK: Work order API

    func fetchWorkOrderWithId(id: String!, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: [:], onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func fetchWorkOrders(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders", method: .GET, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func createWorkOrder(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        var realParams = NSMutableDictionary(dictionary: params)
        realParams.removeObjectForKey("id")
        realParams.removeObjectForKey("customer")
        realParams.removeObjectForKey("companyId")
        realParams.removeObjectForKey("customerId")

        dispatchApiOperationForPath("work_orders", method: .POST, params: realParams, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func updateWorkOrderWithId(id: String!, params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        var realParams = NSMutableDictionary(dictionary: params)
        realParams.removeObjectForKey("id")
        realParams.removeObjectForKey("customer")
        realParams.removeObjectForKey("companyId")
        realParams.removeObjectForKey("customerId")

        dispatchApiOperationForPath("work_orders/\(id)", method: .PUT, params: realParams, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func addAttachment(data: NSData!, withMimeType mimeType: String!, toWorkOrderWithId id: String!, params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/attachments/new", method: .GET, params: ["filename": "upload.\(mimeMappings[mimeType]!)"],
            onSuccess: { (statusCode, mappingResult) -> () in
                assert(statusCode == 200)
                let attachment = mappingResult.firstObject as? Attachment

                self.uploadToS3(NSURL(string: attachment!.url)!, data: data, withMimeType: mimeType, params: attachment!.fields,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        var realParams = NSMutableDictionary(dictionary: params)
                        realParams.setObject(attachment!.fields.objectForKey("key")!, forKey: "key")
                        realParams.setObject(mimeType, forKey: "mime_type")

                        var url = attachment!.url + (attachment!.fields.objectForKey("key") as! String)
                        realParams.setObject(url, forKey: "url")

                        self.dispatchApiOperationForPath("work_orders/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess,
                            onError: { (error, statusCode, responseString) -> () in
                                onError(error: error, statusCode: statusCode, responseString: responseString)
                            }
                        )
                    }, onError: { (error, statusCode, responseString) -> () in
                        onError(error: error, statusCode: statusCode, responseString: responseString)
                    }
                )
            },
            onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    // MARK: Route API

    func fetchRoutes(params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("routes", method: .GET, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func updateRouteWithId(id: String!, params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        var realParams = NSMutableDictionary(dictionary: params)
        realParams.removeObjectForKey("id")

        dispatchApiOperationForPath("routes/\(id)", method: .PUT, params: realParams, onSuccess: { (statusCode, mappingResult) -> () in
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    // MARK: Directions and Routing API

    func getDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: OnSuccess, onError: OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions", method: .GET, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            assert(statusCode == 200 || statusCode == 304)
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    func getDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: OnSuccess, onError: OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions/eta", method: .GET, params: params, onSuccess: { (statusCode, mappingResult) -> () in
            assert(statusCode == 200 || statusCode == 304)
            onSuccess(statusCode: statusCode, mappingResult: mappingResult)
        }) { (error, statusCode, responseString) -> () in
            onError(error: error, statusCode: statusCode, responseString: responseString)
        }
    }

    // MARK: S3

    func uploadToS3(url: NSURL!, data: NSData!, withMimeType mimeType: String!, params: NSDictionary!, onSuccess: OnSuccess, onError: OnError) {
        let api = MKNetworkEngine(hostName: url!.host)
        let path = NSString(string: url!.path!)

        let op = api.operationWithPath((path.length == 0 ? "" : path.substringFromIndex(1)), params: params as! [String : AnyObject], httpMethod: "POST", ssl: true)
        op.addData(data, forKey: "file", mimeType: mimeType, fileName: "filename")

        op.addCompletionHandler(
            { completedOperation in
                let statusCode = completedOperation.HTTPStatusCode
                let responseString = completedOperation.responseString()
                let request = completedOperation.readonlyRequest

                onSuccess(statusCode: statusCode, mappingResult: nil)
            },
            errorHandler: { completedOperation, error in
                onError(error: error, statusCode: completedOperation.HTTPStatusCode, responseString: completedOperation.responseString())
            }
        )
        
        api.enqueueOperation(op)
    }

    private func dispatchApiOperationForPath(path: String!, method: RKRequestMethod! = .GET, params: NSDictionary!, onSuccess: OnSuccess!, onError: OnError!) {
        dispatchOperationForURL(NSURL(string: CurrentEnvironment.baseUrlString), path: "api/\(path)", method: method, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func objectMappingForPath(var path: String!) -> RKObjectMapping! {
        let parts = split(path) { $0 == "/" }
        if parts.count > 3 {
            path = "/".join([parts[1], parts[3]])
            path = path.splitAtString("/").1
        } else {
            path = parts[1]
        }
        return objectMappings[path]
    }

    private func dispatchOperationForURL(baseURL: NSURL!, path: String!, method: RKRequestMethod! = .GET, var params: NSDictionary!, onSuccess: OnSuccess!, onError: OnError!) {
        var responseMapping = objectMappingForPath(path)
        if responseMapping == nil {
            responseMapping = RKObjectMapping(forClass: nil)
        }

        if let responseDescriptor = RKResponseDescriptor(mapping: responseMapping, method: method, pathPattern: nil, keyPath: nil, statusCodes: nil) {
            var urlComponents = NSURLComponents(URL: baseURL.URLByAppendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if method == .GET && params.count > 0 {
                urlComponents.query = params.toQueryString()
            }

            var request = NSMutableURLRequest(URL: urlComponents.URL!)
            request.HTTPMethod = RKStringFromRequestMethod(method)
            request.HTTPShouldHandleCookies = false
            request.setValue("application/json", forHTTPHeaderField: "content-type")

            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }

            if contains([.POST, .PUT], method) {
                params = NSMutableDictionary(dictionary: params)
                for key in params.allKeys {
                    var value: AnyObject? = params.objectForKey(key)
                    if value != nil && value!.isKindOfClass(NSArray) {
                        var newValue = NSMutableArray()
                        for item in (value as! NSArray) {
                            if item.isKindOfClass(Model) {
                                newValue.addObject((item as! Model).toDictionary())
                            }
                        }
                        (params as! NSMutableDictionary).setObject(newValue, forKey: key as! String)
                    }
                }

                request.HTTPBody = params?.toJSON().dataUsingEncoding(NSUTF8StringEncoding)
            }

            if let op = RKObjectRequestOperation(request: request, responseDescriptors: [responseDescriptor]) {
                op.setCompletionBlockWithSuccess({ (operation, mappingResult) -> Void in
                    onSuccess(statusCode: operation.HTTPRequestOperation.response.statusCode, mappingResult: mappingResult)
                    return
                }, failure: { (operation, error) -> Void in
                    onError(error: error,
                        statusCode: operation.HTTPRequestOperation.response.statusCode,
                        responseString: operation.HTTPRequestOperation.responseString)
                })

                op.start()
            }
        }
    }
}
