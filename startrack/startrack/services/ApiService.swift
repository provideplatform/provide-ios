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
        "casting_demands": CastingDemand.mapping(),
        "companies": Company.mapping(),
        "devices": Device.mapping(),
        "directions": Directions.mapping(),
        "eta": Directions.mapping(),
        "products": Product.mapping(),
        "productions": Production.mapping(),
        "providers": Provider.mapping(),
        "recommendations": Provider.mapping(),
        "routes": Route.mapping(),
        "shooting_dates": ShootingDate.mapping(),
        "tokens": Token.mapping(),
        "work_orders": WorkOrder.mapping(),
        "users": User.mapping(),
        "messages": Message.mapping(),
    ]

    private let initialBackoffTimeout: NSTimeInterval = 0.1
    private var backoffTimeout: NSTimeInterval!

    private var headers = [String : String]()

    private static let sharedInstance = ApiService()

    class func sharedService() -> ApiService {
         return sharedInstance
    }

    override init() {
        super.init()

        backoffTimeout = initialBackoffTimeout

        if let token = KeyChainService.sharedService().token {
            headers["X-API-Authorization"] = token.authorizationHeaderString

            CheckinService.sharedService().start()
            LocationService.sharedService().start()
        }
    }

    // MARK: Token API

    class func hasCachedToken() -> Bool {
        if let token = KeyChainService.sharedService().token {
            let hasCachedToken = token.user != nil
            if !hasCachedToken {
                KeyChainService.sharedService().token = nil
            }
            return hasCachedToken
        }

        return false
    }

    func login(params: [String: String], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("tokens", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                let token = mappingResult.firstObject as! Token
                self.headers["X-API-Authorization"] = token.authorizationHeaderString
                KeyChainService.sharedService().token = token
                KeyChainService.sharedService().email = params["email"]

                AnalyticsService.sharedService().identify(token.user)

                self.registerForRemoteNotifications()
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
                KeyChainService.sharedService().clearStoredUserData()
            }
        )
    }

    func logout(onSuccess: OnSuccess, onError: OnError) {
        unregisterForRemoteNotifications()
        
        if let token = KeyChainService.sharedService().token {
            dispatchApiOperationForPath("tokens/\(token.id)", method: .DELETE, params: nil,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                    self.localLogout()
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                    self.localLogout()
                }
            )
        }
    }

    private func localLogout() {
        CheckinService.sharedService().stop()
        LocationService.sharedService().stop()
        headers.removeValueForKey("X-API-Authorization")
        KeyChainService.sharedService().clearStoredUserData()
        AnalyticsService.sharedService().logout()
    }

    // MARK: User API

    func fetchUser(onSuccess onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("users/\(currentUser().id)", method: .GET, params: [:],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200)
                let user = mappingResult.firstObject as! User
                if let token = KeyChainService.sharedService().token {
                    token.user = user
                    KeyChainService.sharedService().token = token
                }
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func updateUser(params: [String: String], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("users/\(currentUser().id)", method: .PUT, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 204)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func setUserDefaultProfileImage(image: UIImage, onSuccess: OnSuccess, onError: OnError) {
        let params = [
            "public": false,
            "tags": ["profile_image", "default"]
        ]

        let data = UIImageJPEGRepresentation(image, 1.0)

        ApiService.sharedService().addAttachment(data!,
            withMimeType: "image/jpg",
            toUserWithId: String(currentUser().id),
            params: params,
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)

                ApiService.sharedService().fetchUser(
                    onSuccess: { statusCode, mappingResult in
                        NSNotificationCenter.defaultCenter().postNotificationName("ProfileImageShouldRefresh")
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toUserWithId id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("users/\(id)/attachments/new", method: .GET, params: ["filename": "upload.\(mimeMappings[mimeType]!)"],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200)
                let attachment = mappingResult.firstObject as? Attachment

                self.uploadToS3(attachment!.url, data: data, withMimeType: mimeType, params: attachment!.fields as! [String : AnyObject],
                    onSuccess: { statusCode, mappingResult in
                        var realParams = params
                        realParams.updateValue(attachment!.fields["key"]!, forKey: "key")
                        realParams.updateValue(mimeType, forKey: "mime_type")

                        let url = attachment!.urlString + (attachment!.fields.objectForKey("key") as! String)
                        realParams.updateValue(url, forKey: "url")

                        self.dispatchApiOperationForPath("users/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    onError: onError
                )
            },
            onError: onError
        )
    }

    // MARK: Device API

    func createDevice(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("devices", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                KeyChainService.sharedService().deviceId = (mappingResult.firstObject as! Device).id.description
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func deleteDeviceWithId(deviceId: String, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("devices/\(deviceId)", method: .DELETE, params: nil, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Remote notifications

    private func registerForRemoteNotifications() {
        if !isSimulator() {
            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert]
            let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        }
    }

    private func unregisterForRemoteNotifications() {
        if !isSimulator() {
            UIApplication.sharedApplication().unregisterForRemoteNotifications()

            if let deviceId = KeyChainService.sharedService().deviceId {
                ApiService.sharedService().deleteDeviceWithId(deviceId,
                    onSuccess: { statusCode, mappingResult in

                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
    }

    // MARK: Provider API

    func fetchProviders(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("providers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderAvailability(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("providers/\(id)/availability", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Checkin API

    func checkin(location: CLLocation) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let checkinDate = dateFormatter.stringFromDate(location.timestamp)

        let longitude = location.coordinate.longitude
        let latitude = location.coordinate.latitude

        let params: [String: AnyObject] = ["latitude": latitude, "longitude": longitude, "checkin_at": checkinDate]

        checkin(params,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func checkin(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("checkins", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    // MARK: Work order API

    func fetchWorkOrderWithId(id: String, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrders(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createWorkOrder(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["customer"] = nil
        realParams["companyId"] = nil
        realParams["customerId"] = nil

        dispatchApiOperationForPath("work_orders", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateWorkOrderWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["customer"] = nil
        realParams["companyId"] = nil
        realParams["customerId"] = nil

        dispatchApiOperationForPath("work_orders/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forWorkOrderWithId id: String, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toWorkOrderWithId id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/attachments/new", method: .GET, params: ["filename": "upload.\(mimeMappings[mimeType]!)"],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200)
                let attachment = mappingResult.firstObject as? Attachment

                self.uploadToS3(attachment!.url, data: data, withMimeType: mimeType, params: (attachment!.fields as! [String : AnyObject]),
                    onSuccess: { statusCode, mappingResult in
                        var realParams = params
                        realParams.updateValue(attachment!.fields["key"]!, forKey: "key")
                        realParams.updateValue(mimeType, forKey: "mime_type")

                        let url = attachment!.urlString + (attachment!.fields.objectForKey("key") as! String)
                        realParams.updateValue(url, forKey: "url")

                        self.dispatchApiOperationForPath("work_orders/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    onError: onError
                )
            },
            onError: onError
        )
    }

    // MARK: Comments API

    func addComment(comment: String, toWorkOrderWithId id: String!, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/comments", method: .POST, params: ["body": comment],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    // MARK: Route API

    func fetchRoutes(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("routes", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchRouteWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("routes/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateRouteWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        var realParams = params
        realParams.removeValueForKey("id")

        dispatchApiOperationForPath("routes/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Directions and Routing API

    func getDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: OnSuccess, onError: OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions", method: .GET, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200 || statusCode == 304)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func getDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: OnSuccess, onError: OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions/eta", method: .GET, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200 || statusCode == 304)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    // MARK: - Messages API

    func fetchMessages(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("messages", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createMessage(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("messages", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Productions API

    func fetchProductions(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("productions", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchUniqueShootingDatesForProductionWithId(id: String, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("productions/\(id)/shooting_dates", method: .GET, params: [String: AnyObject](), onSuccess: onSuccess, onError: onError)
    }

    func fetchCastingDemands(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("casting_demands", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderRecommendationsForCastingDemandWithId(id: String, onSuccess: OnSuccess, onError: OnError) {
        dispatchApiOperationForPath("casting_demands/\(id)/recommendations", method: .GET, params: [String: AnyObject](), onSuccess: onSuccess, onError: onError)
    }

    // MARK: S3

    func uploadToS3(url: NSURL, data: NSData, withMimeType mimeType: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        let api = MKNetworkEngine(hostName: url.host)
        let path = NSString(string: url.path!)

        let op = api.operationWithPath((path.length == 0 ? "" : path.substringFromIndex(1)), params: params, httpMethod: "POST", ssl: true)
        op.addData(data, forKey: "file", mimeType: mimeType, fileName: "filename")

        op.addCompletionHandler(
            { completedOperation in
                let statusCode = completedOperation.HTTPStatusCode
                onSuccess(statusCode: statusCode, mappingResult: nil)
            },
            errorHandler: { completedOperation, error in
                onError(error: error, statusCode: completedOperation.HTTPStatusCode, responseString: completedOperation.responseString())
            }
        )

        api.enqueueOperation(op)
    }

    private func dispatchApiOperationForPath(path: String, method: RKRequestMethod! = .GET, params: [String: AnyObject]?, onSuccess: OnSuccess, onError: OnError) {
        dispatchOperationForURL(NSURL(CurrentEnvironment.baseUrlString), path: "api/\(path)", method: method, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func objectMappingForPath(var path: String) -> RKObjectMapping? {
        let parts = path.characters.split("/").map { String($0) }
        if parts.count > 3 {
            path = [parts[1], parts[3]].joinWithSeparator("/")
            path = path.splitAtString("/").1
        } else {
            path = parts[1]
        }
        return objectMappings[path]
    }

    private func dispatchOperationForURL(baseURL: NSURL, path: String, method: RKRequestMethod = .GET, var params: [String: AnyObject]!, onSuccess: OnSuccess, onError: OnError) {
        var responseMapping = objectMappingForPath(path)
        if responseMapping == nil {
            responseMapping = RKObjectMapping(forClass: nil)
        }

        if let responseDescriptor = RKResponseDescriptor(mapping: responseMapping, method: method, pathPattern: nil, keyPath: nil, statusCodes: nil) {
            let urlComponents = NSURLComponents(URL: baseURL.URLByAppendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if method == .GET && params.count > 0 {
                urlComponents.query = params.toQueryString()
            }

            let request = NSMutableURLRequest(URL: urlComponents.URL!)
            request.HTTPMethod = RKStringFromRequestMethod(method)
            request.HTTPShouldHandleCookies = false
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("application/json", forHTTPHeaderField: "content-type")

            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }

            var jsonParams: String!
            if let _ = params {
                for key in params.keys {
                    let value: AnyObject? = params[key]
                    if value != nil && value!.isKindOfClass(NSArray) {
                        let newValue = NSMutableArray()
                        for item in (value as! NSArray) {
                            if item.isKindOfClass(Model) {
                                newValue.addObject((item as! Model).toDictionary())
                            } else {
                                newValue.addObject(item)
                            }
                        }
                        params.updateValue(newValue, forKey: key)
                    }
                }

                jsonParams = NSDictionary(dictionary: params).toJSON() // FIXME-- make sure content type is suitable for this operation
            } else {
                jsonParams = "{}"
            }

            if [.POST, .PUT].contains(method) {
                request.HTTPBody = jsonParams!.dataUsingEncoding(NSUTF8StringEncoding)
            }

            if let op = RKObjectRequestOperation(request: request, responseDescriptors: [responseDescriptor]) {
                let startDate = NSDate()

                op.setCompletionBlockWithSuccess(
                    { operation, mappingResult in
                        self.backoffTimeout = self.initialBackoffTimeout

                        AnalyticsService.sharedService().track("HTTP Request Succeeded", properties: ["path": path,
                                                                                                      "statusCode": operation.HTTPRequestOperation.response.statusCode,
                                                                                                      "params": jsonParams,
                                                                                                      "execTimeMillis": NSDate().timeIntervalSinceDate(startDate) * 1000.0])

                        onSuccess(statusCode: operation.HTTPRequestOperation.response.statusCode,
                                  mappingResult: mappingResult)
                    },
                    failure: { operation, error in
                        let receivedResponse = operation.HTTPRequestOperation.response != nil
                        let responseString = receivedResponse ? operation.HTTPRequestOperation.responseString : "{}"
                        let statusCode = receivedResponse ? operation.HTTPRequestOperation.response.statusCode : -1

                        if receivedResponse {
                            AnalyticsService.sharedService().track("HTTP Request Failed", properties: ["path": path,
                                                                                                       "statusCode": statusCode,
                                                                                                       "params": jsonParams,
                                                                                                       "responseString": responseString,
                                                                                                       "execTimeMillis": NSDate().timeIntervalSinceDate(startDate) * 1000.0])
                        } else if let err = error {
                            AnalyticsService.sharedService().track("HTTP Request Failed", properties: ["error": err.localizedDescription,
                                                                                                       "code": err.code,
                                                                                                       "params": jsonParams,
                                                                                                       "execTimeMillis": NSDate().timeIntervalSinceDate(startDate) * 1000.0])

                            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(self.backoffTimeout * Double(NSEC_PER_SEC)))
                            dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                                self.dispatchOperationForURL(baseURL,
                                                             path: path,
                                                             method: method,
                                                             params: params,
                                                             onSuccess: onSuccess,
                                                             onError: onError)
                            }

                            self.backoffTimeout = self.backoffTimeout > 60.0 ? self.initialBackoffTimeout : self.backoffTimeout * 2
                        }

                        onError(error: error,
                                statusCode: statusCode,
                                responseString: responseString)
                    }
                )

                op.start()
            }
        }
    }
}
