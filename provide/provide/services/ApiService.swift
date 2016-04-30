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
typealias OnURLFetched = (statusCode: Int, response: NSData) -> ()
typealias OnImageFetched = (statusCode: Int, response: UIImage) -> ()
typealias OnTotalResultsCount = (totalResultsCount: Int, error: NSError!) -> ()

class ApiService: NSObject {

    private let mimeMappings = [
        "application/pdf": "pdf",
        "image/jpg": "jpg",
        "image/x-dwg": "dwg",
        "video/mp4": "m4v",
    ]

    private let objectMappings: [String : AnyObject] = [
        "attachments": Attachment.mappingWithRepresentations(),
        "annotations": Annotation.mapping(),
        "categories": Category.mapping(),
        "comments": Comment.mapping(),
        "companies": Company.mapping(),
        "customers": Customer.mapping(),
        "devices": Device.mapping(),
        "directions": Directions.mapping(),
        "estimates": Estimate.mapping(),
        "eta": Directions.mapping(),
        "expenses": Expense.mapping(),
        "floorplans": Floorplan.mapping(),
        "invitations": Invitation.mapping(),
        "jobs": Job.mapping(),
        "job_products": JobProduct.mapping(),
        "products": Product.mapping(),
        "providers": Provider.mapping(),
        "routes": Route.mapping(),
        "tasks": Task.mapping(),
        "tokens": Token.mapping(),
        "work_orders": WorkOrder.mapping(),
        "work_order_products": WorkOrderProduct.mapping(),
        "users": ["*": User.mapping(), "post": UserToken.mapping()],
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
        }
    }

    var defaultCompanyId: Int! {
        let defaultCompanyId = currentUser().defaultCompanyId
        if defaultCompanyId > 0 {
            return defaultCompanyId
        }
        return nil
    }

    // MARK: Token API

    var hasCachedToken: Bool {
        if let token = KeyChainService.sharedService().token {
            let hasCachedToken = token.user != nil
            if !hasCachedToken {
                KeyChainService.sharedService().token = nil
            }
            return hasCachedToken
        }

        return false
    }

    func setToken(token: Token) {
        self.headers["X-API-Authorization"] = token.authorizationHeaderString
        KeyChainService.sharedService().token = token
        KeyChainService.sharedService().email = token.user.email

        AnalyticsService.sharedService().identify(token.user)

        self.registerForRemoteNotifications()

        NotificationService.sharedService().connectWebsocket()
    }

    func login(params: [String: String], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("tokens", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                let token = mappingResult.firstObject as! Token
                self.setToken(token)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
                KeyChainService.sharedService().clearStoredUserData()
            }
        )
    }

    func logout(onSuccess: OnSuccess, onError: OnError) {
        if !isSimulator() {
            unregisterForRemoteNotifications()
        }

        deleteToken(onSuccess, onError: onError)
    }

    private func forceLogout() {
        if !isSimulator() {
            unregisterForRemoteNotifications()
        }

        localLogout()

        NSNotificationCenter.defaultCenter().postNotificationName("ApplicationUserLoggedOut")
    }

    private func deleteToken(onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        if let token = KeyChainService.sharedService().token {
            return dispatchApiOperationForPath("tokens/\(token.id)", method: .DELETE, params: nil,
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

        return nil
    }

    private func localLogout() {
        CheckinService.sharedService().stop()
        LocationService.sharedService().stop()
        NotificationService.sharedService().disconnectWebsocket()
        headers.removeValueForKey("X-API-Authorization")
        KeyChainService.sharedService().clearStoredUserData()
        AnalyticsService.sharedService().logout()
        ImageService.sharedService().clearCache()

        backoffTimeout = nil
    }

    // MARK: Fetch images

    func fetchURL(url: NSURL, onURLFetched: OnURLFetched, onError: OnError) {
        let api = MKNetworkEngine(hostName: url.host)
        let path = NSString(string: url.path!)

        let params = url.query != nil ? url.query!.toJSONObject() : [:]
        let op = api.operationWithPath((path.length == 0 ? "" : path.substringFromIndex(1)), params: params, httpMethod: "GET", ssl: url.scheme == "https")

        op.addCompletionHandler(
            { completedOperation in
                let statusCode = completedOperation.HTTPStatusCode
                onURLFetched(statusCode: statusCode, response: completedOperation.responseData())
            },
            errorHandler: { completedOperation, error in
                onError(error: error, statusCode: completedOperation.HTTPStatusCode, responseString: completedOperation.responseString())
            }
        )

        api.enqueueOperation(op)
    }

    func fetchImage(url: NSURL, onImageFetched: OnImageFetched, onError: OnError) {
        let api = MKNetworkEngine(hostName: url.host)
        let path = NSString(string: url.path!)

        let params = url.query != nil ? url.query!.toJSONObject() : [:]
        let op = api.operationWithPath((path.length == 0 ? "" : path.substringFromIndex(1)), params: params, httpMethod: "GET", ssl: url.scheme == "https")

        op.addCompletionHandler(
            { completedOperation in
                let statusCode = completedOperation.HTTPStatusCode
                onImageFetched(statusCode: statusCode, response: completedOperation.responseImage())
            },
            errorHandler: { completedOperation, error in
                onError(error: error, statusCode: completedOperation.HTTPStatusCode, responseString: completedOperation.responseString())
            }
        )

        api.enqueueOperation(op)
    }

    // MARK: Attachments API

    func updateAttachmentWithId(id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Annotations API

    func fetchAnnotationsForAttachmentWithId(id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)/annotations", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createAnnotationForAttachmentWithId(id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)/annotations", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAnnotationWithId(id: String, forAttachmentWithId attachmentId: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(attachmentId)/annotations/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Company API

    func fetchCompanies(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("companies", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Invitation API

    func fetchInvitationWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("invitations/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    // MARK: User API

    func createUser(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("users", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                let userToken = mappingResult.firstObject as! UserToken
                if let token = userToken.token {
                    token.user = userToken.user
                    self.setToken(token)
                }
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func fetchUser(onSuccess onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("users/\(currentUser().id)", method: .GET, params: [:],
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

    func updateUser(params: [String: String], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("users/\(currentUser().id)", method: .PUT, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 204)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func setUserDefaultProfileImage(image: UIImage, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        let params = [
            "public": false,
            "tags": ["profile_image", "default"]
        ]

        let data = UIImageJPEGRepresentation(image, 1.0)

        return ApiService.sharedService().addAttachment(data!,
            withMimeType: "image/jpg",
            toUserWithId: String(currentUser().id),
            params: params,
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)

                ApiService.sharedService().fetchUser(
                    onSuccess: { statusCode, mappingResult in
                        if !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
                            NSNotificationCenter.defaultCenter().postNotificationName("ProfileImageShouldRefresh")
                        }
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

    func addAttachment(data: NSData, withMimeType mimeType: String, toUserWithId id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("users/\(id)/attachments/new", method: .GET, params: presignParams,
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

    func updateAttachmentWithId(id: String, onUserWithId userId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("users/\(userId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Device API

    func createDevice(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("devices", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func deleteDeviceWithId(deviceId: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("devices/\(deviceId)", method: .DELETE, params: nil, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Remote notifications

    func registerForRemoteNotifications() {
        if !isSimulator() {
            NSNotificationCenter.defaultCenter().postNotificationName("ApplicationWillRegisterUserNotificationSettings")

            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert]
            let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        }
    }

    func unregisterForRemoteNotifications() {
        if !isSimulator() {
            UIApplication.sharedApplication().unregisterForRemoteNotifications()
        }
    }

    // MARK: Category API

    func countCategories(params: [String: AnyObject], onTotalResultsCount: OnTotalResultsCount) -> RKObjectRequestOperation! {
        return countTotalResultsForPath("categories", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchCategories(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("categories", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Customer API

    func countCustomers(params: [String: AnyObject], onTotalResultsCount: OnTotalResultsCount) -> RKObjectRequestOperation! {
        return countTotalResultsForPath("customers", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchCustomers(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("customers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchCustomerWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("customers/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    // MARK: Provider API

    func countProviders(params: [String : AnyObject], onTotalResultsCount: OnTotalResultsCount) -> RKObjectRequestOperation! {
        return countTotalResultsForPath("providers", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchProviders(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("providers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("providers/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderAvailability(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("providers/\(id)/availability", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createProvider(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil

        return dispatchApiOperationForPath("providers", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateProviderWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil
        realParams["customerId"] = nil

        return dispatchApiOperationForPath("providers/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Checkin API

    func checkin(location: CLLocation) -> RKObjectRequestOperation! {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let checkinDate = dateFormatter.stringFromDate(location.timestamp)

        let longitude = location.coordinate.longitude
        let latitude = location.coordinate.latitude

        let params: [String: AnyObject] = ["latitude": latitude, "longitude": longitude, "checkin_at": checkinDate]

        return checkin(params,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func checkin(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("checkins", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    // MARK: Task API

    func fetchTaskWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("tasks/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchTaskWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("tasks/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchTasks(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("tasks", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createTask(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil
        realParams["userId"] = nil

        return dispatchApiOperationForPath("tasks", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateTaskWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil
        realParams["userId"] = nil

        return dispatchApiOperationForPath("tasks/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Work order API

    func fetchWorkOrderWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrderWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrders(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createWorkOrder(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil
        realParams["customer"] = nil
        realParams["companyId"] = nil
        realParams["customerId"] = nil

        return dispatchApiOperationForPath("work_orders", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateWorkOrderWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil
        realParams["company"] = nil
        realParams["customer"] = nil
        realParams["companyId"] = nil
        realParams["customerId"] = nil

        return dispatchApiOperationForPath("work_orders/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forWorkOrderWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toWorkOrderWithId id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("work_orders/\(id)/attachments/new", method: .GET, params: presignParams,
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

    func updateAttachmentWithId(id: String, onWorkOrderWithId workOrderId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(workOrderId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Comments API

    func fetchComments(params: [String : AnyObject], forCommentableType commentableType: String, withCommentableId commentableId: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("\(commentableType)s/\(commentableId)/comments", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchComments(forJobWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)/comments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addComment(comment: String, toJobWithId id: String!, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)/comments", method: .POST, params: ["body": comment],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func fetchComments(forWorkOrderWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(id)/comments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addComment(comment: String, toWorkOrderWithId id: String!, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(id)/comments", method: .POST, params: ["body": comment],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toCommentWithId id: String, forCommentableType commentableType: String, withCommentableId commentableId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("\(commentableType)s/\(commentableId)/comments/\(id)/attachments/new", method: .GET, params: presignParams,
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

                                                    self.dispatchApiOperationForPath("\(commentableType)s/\(commentableId)/comments/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                                                },
                                                onError: onError
                                            )
            },
                                           onError: onError
        )
    }

    // MARK: Products API

    func countProducts(params: [String : AnyObject], onTotalResultsCount: OnTotalResultsCount) -> RKObjectRequestOperation! {
        return countTotalResultsForPath("products", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchProducts(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("products", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createProduct(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil

        return dispatchApiOperationForPath("products", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateProductWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil

        return dispatchApiOperationForPath("products/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Route API

    func fetchRoutes(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("routes", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchRouteWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("routes/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateRouteWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams.removeValueForKey("id")

        return dispatchApiOperationForPath("routes/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Directions and Routing API

    func getDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        return dispatchApiOperationForPath("directions", method: .GET, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200 || statusCode == 304)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    func getDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        return dispatchApiOperationForPath("directions/eta", method: .GET, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200 || statusCode == 304)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: onError
        )
    }

    // MARK: Floorplans API

    func fetchFloorplans(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("floorplans", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchFloorplanWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("floorplans/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchFloorplanWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("floorplans/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createFloorplan(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil

        return dispatchApiOperationForPath("floorplans", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateFloorplanWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil

        return dispatchApiOperationForPath("floorplans/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forFloorplanWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("floorplans/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toFloorplanWithId id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("floorplans/\(id)/attachments/new", method: .GET, params: presignParams,
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

                        self.dispatchApiOperationForPath("floorplans/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    onError: onError
                )
            },
            onError: onError
        )
    }

    func addAttachmentFromSourceUrl(sourceUrl: NSURL, toFloorplanWithId id: String, var params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        params["source_url"] = sourceUrl.absoluteString
        return dispatchApiOperationForPath("floorplans/\(id)/attachments", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(id: String, onFloorplanWithId floorplanId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("floorplans/\(floorplanId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Jobs API

    func fetchJobs(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchJobWithId(id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchJobWithId(id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createJob(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil
//        realParams["companyId"] = nil

        return dispatchApiOperationForPath("jobs", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateJobWithId(id: String, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var realParams = params
        realParams["id"] = nil

        return dispatchApiOperationForPath("jobs/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forJobWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toJobWithId id: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("jobs/\(id)/attachments/new", method: .GET, params: presignParams,
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

                        self.dispatchApiOperationForPath("jobs/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    onError: onError
                )
            },
            onError: onError
        )
    }

    func addAttachmentFromSourceUrl(sourceUrl: NSURL, toJobWithId id: String, var params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        params["source_url"] = sourceUrl.absoluteString
        return dispatchApiOperationForPath("jobs/\(id)/attachments", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(id: String, onJobWithId jobId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(jobId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Estimates API

    func fetchEstimates(forJobWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)/estimates", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchEstimateWithId(id: String, forJobWithId jobId: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func createEstimate(params: [String : AnyObject], forJobWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)/estimates", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachmentFromSourceUrl(sourceUrl: NSURL, toEstimateWithId id: String, forJobWithId jobId: String, var params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        params["source_url"] = sourceUrl.absoluteString
        return dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(id)/attachments", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toEstimateWithId id: String, forJobWithId jobId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(id)/attachments/new", method: .GET, params: presignParams,
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

                        self.dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    onError: onError
                )
            },
            onError: onError
        )
    }

    func updateAttachmentWithId(id: String, forEstimateWithId estimateId: String, onJobWithId jobId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(estimateId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Expenses API

    func fetchExpenses(forJobWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("jobs/\(id)/expenses", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchExpenses(forWorkOrderWithId id: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("work_orders/\(id)/expenses", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func createExpense(params: [String : AnyObject], forExpensableType expensableType: String, withExpensableId expensableId: String, onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("\(expensableType)s/\(expensableId)/expenses", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(data: NSData, withMimeType mimeType: String, toExpenseWithId id: String, forExpensableType expensableType: String, withExpensableId expensableId: String, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        var presignParams: [String : AnyObject] = ["filename": "upload.\(mimeMappings[mimeType]!)"]
        if let tags = params["tags"] {
            presignParams["metadata"] = "{\"tags\": \"\((tags as! [String]).joinWithSeparator(","))\"}"
        }
        return dispatchApiOperationForPath("\(expensableType)s/\(expensableId)/expenses/\(id)/attachments/new", method: .GET, params: presignParams,
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

                        self.dispatchApiOperationForPath("\(expensableType)s/\(expensableId)/expenses/\(id)/attachments", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    onError: onError
                )
            },
            onError: onError
        )
    }

    // MARK: - Messages API

    func fetchMessages(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("messages", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createMessage(params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("messages", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
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

    // MARK: Private methods

    private func countTotalResultsForPath(path: String, var params: [String : AnyObject], onTotalResultsCount: OnTotalResultsCount) -> RKObjectRequestOperation {
        params["page"] = 1
        params["rpp"] = 0

        let op = dispatchApiOperationForPath(path, method: .GET, params: params, startOperation: false,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )

        op.setCompletionBlockWithSuccess(
            { operation, mappingResult in
                let headers = operation.HTTPRequestOperation.response.allHeaderFields
                if let totalResultsCountString = headers["X-Total-Results-Count"] as? String {
                    if let totalResultsCount = Int(totalResultsCountString) {
                        onTotalResultsCount(totalResultsCount: totalResultsCount, error: nil)
                    }
                }
            },
            failure: { operation, error in
                onTotalResultsCount(totalResultsCount: -1, error: error)
            }
        )

        op.start()

        return op
    }

    private func dispatchApiOperationForPath(path: String,
                                             method: RKRequestMethod! = .GET,
                                             params: [String: AnyObject]?,
                                             startOperation: Bool = true,
                                             onSuccess: OnSuccess,
                                             onError: OnError) -> RKObjectRequestOperation! {
        return dispatchOperationForURL(NSURL(CurrentEnvironment.baseUrlString),
                                       path: "api/\(path)",
                                       method: method,
                                       params: params,
                                       contentType: "application/json",
                                       startOperation: startOperation,
                                       onSuccess: onSuccess,
                                       onError: onError)
    }

    private func objectMappingForPath(var path: String, method: String) -> RKObjectMapping? {
        let parts = path.characters.split("/").map { String($0) }
        if parts.count > 5 {
            path = [parts[3], parts[5]].joinWithSeparator("/")
            path = path.splitAtString("/").1
        } else if parts.count > 3 {
            path = [parts[1], parts[3]].joinWithSeparator("/")
            path = path.splitAtString("/").1
        } else {
            path = parts[1]
        }

        var mapping: RKObjectMapping?

        if let object = objectMappings[path] {
            if object is RKObjectMapping {
                mapping = object as? RKObjectMapping
            } else if object is [String : RKObjectMapping] {
                for entry in (object as! [String : RKObjectMapping]).enumerate() {
                    if entry.element.0 == method {
                        mapping = entry.element.1
                        break
                    } else if entry.element.0 == "*" {
                        mapping = entry.element.1
                    }
                }
            }
        }

        return mapping
    }

    private func dispatchOperationForURL(baseURL: NSURL,
                                         path: String,
                                         method: RKRequestMethod = .GET,
                                         params: [String : AnyObject]!,
                                         contentType: String = "application/json",
                                         startOperation: Bool = true,
                                         onSuccess: OnSuccess,
                                         onError: OnError) -> RKObjectRequestOperation! {
        var responseMapping = objectMappingForPath(path, method: RKStringFromRequestMethod(method).lowercaseString)
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
            request.setValue(contentType, forHTTPHeaderField: "content-type")

            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }

            var jsonParams: String!
            if let _ = params {
                if contentType.lowercaseString == "application/json" {
                    jsonParams = NSDictionary(dictionary: params).toJSON()
                }
            } else {
                jsonParams = "{}"
            }

            if [.POST, .PUT].contains(method) {
                if let jsonParams = jsonParams {
                    request.HTTPBody = jsonParams.dataUsingEncoding(NSUTF8StringEncoding)
                }
            }

            if let op = RKObjectRequestOperation(request: request, responseDescriptors: [responseDescriptor]) {
                let startDate = NSDate()

                op.setCompletionBlockWithSuccess(
                    { operation, mappingResult in
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
                            self.backoffTimeout = self.initialBackoffTimeout

                            AnalyticsService.sharedService().track("HTTP Request Failed", properties: ["path": path,
                                                                                                       "statusCode": statusCode,
                                                                                                       "params": jsonParams,
                                                                                                       "responseString": responseString,
                                                                                                       "execTimeMillis": NSDate().timeIntervalSinceDate(startDate) * 1000.0])

                            if statusCode == 401 {
                                if baseURL.absoluteString == CurrentEnvironment.baseUrlString {
                                    self.forceLogout()
                                }
                            }
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

                if startOperation {
                    op.start()
                }
                
                return op
            }
        }

        return nil
    }
}
