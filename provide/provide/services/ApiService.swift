//
//  ApiService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit
import KTSwiftExtensions
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import JWTDecode

typealias OnSuccess = (_ statusCode: Int, _ mappingResult: RKMappingResult?) -> ()
typealias OnError = (_ error: NSError, _ statusCode: Int, _ responseString: String) -> ()
typealias OnURLFetched = (_ statusCode: Int, _ response: Data) -> ()
typealias OnImageFetched = (_ statusCode: Int, _ response: UIImage) -> ()
typealias OnTotalResultsCount = (_ totalResultsCount: Int, _ error: NSError?) -> ()

class ApiService: NSObject {

    fileprivate let mimeMappings = [
        "application/pdf": "pdf",
        "image/jpg": "jpg",
        "image/x-dwg": "dwg",
        "video/mp4": "m4v",
    ]

    fileprivate static let usersMapping: [String : AnyObject] = ["*": User.mapping(), "post": UserToken.mapping()]

    fileprivate let objectMappings: [String : AnyObject] = [
        "attachments": Attachment.mappingWithRepresentations(),
        "comments": Comment.mapping(),
        "companies": Company.mapping(),
        "customers": Customer.mapping(),
        "devices": Device.mapping(),
        "directions": Directions.mapping(),
        "eta": Directions.mapping(),
        "invitations": Invitation.mapping(),
        "providers": Provider.mapping(),
        "tokens": Token.mapping(),
        "work_orders": WorkOrder.mapping(),
        "users": ApiService.usersMapping as AnyObject,
        "messages": Message.mapping(),
    ]

    fileprivate let initialBackoffTimeout: TimeInterval = 0.1
    fileprivate var backoffTimeout: TimeInterval!

    fileprivate var headers = [String : String]()

    fileprivate var requestOperations = [RKObjectRequestOperation]()

    fileprivate static let sharedInstance = ApiService()

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

    func setToken(_ token: Token) {
        self.headers["X-API-Authorization"] = token.authorizationHeaderString
        KeyChainService.sharedService().token = token
        KeyChainService.sharedService().email = token.user.email

        AnalyticsService.sharedService().identify(token.user)

        self.registerForRemoteNotifications()

        NotificationService.sharedService().connectWebsocket()
    }

    func login(_ jwt: JWT) -> Bool {
        let tokenId = jwt.body["token_id"] as? Int
        let token = jwt.body["token"] as? String
        let uuid = jwt.body["token_uuid"] as? String
        let userId = jwt.body["user_id"] as? Int
        let userEmail = jwt.body["email"] as? String
        let userName = jwt.body["name"] as? String

        if tokenId != nil && token != nil && uuid != nil && userId != nil && userEmail != nil && userName != nil {
            let t = Token()
            t.id = tokenId!
            t.token = token
            t.uuid = uuid

            let user = User()
            user.id = userId!
            user.email = userEmail!
            user.name = userName!
            t.user = user

            setToken(t)

            return true
        }

        return false
    }

    func login(_ params: [String: String], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tokens", method: .POST, params: params as [String : AnyObject]?,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                let token = mappingResult?.firstObject as! Token
                self.setToken(token)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
                KeyChainService.sharedService().clearStoredUserData()
            }
        )
    }

    func logout(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if !isSimulator() {
            unregisterForRemoteNotifications()
        }

        deleteToken(onSuccess, onError: onError)
    }

    fileprivate func forceLogout() {
        if !isSimulator() {
            unregisterForRemoteNotifications()
        }

        localLogout()

        NotificationCenter.default.postNotificationName("ApplicationUserLoggedOut")
    }

    fileprivate func deleteToken(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if let token = KeyChainService.sharedService().token {
            dispatchApiOperationForPath("tokens/\(token.id)", method: .DELETE, params: nil,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode, mappingResult)
                    self.localLogout()
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                    self.localLogout()
                }
            )
        }
    }

    fileprivate func localLogout() {
        CheckinService.sharedService().stop()
        LocationService.sharedService().stop()
        NotificationService.sharedService().disconnectWebsocket()
        headers.removeValue(forKey: "X-API-Authorization")
        KeyChainService.sharedService().clearStoredUserData()
        AnalyticsService.sharedService().logout()
        ImageService.sharedService().clearCache()

        backoffTimeout = nil
    }

    // MARK: Fetch images

    func fetchURL(_ url: URL, onURLFetched: @escaping OnURLFetched, onError: OnError) {
        let params = url.query != nil ? url.query!.toJSONObject() : [:]
        let request = Alamofire.request(url.absoluteString, method: .get, parameters: params)
        KTApiService.sharedService().execute(request,
            successHandler: { response in
                let statusCode = response!.response!.statusCode
                onURLFetched(statusCode, response!.responseData)
            },
            failureHandler: { response, statusCode, error in

            }
        )
    }

    // MARK: Attachments API

    func updateAttachmentWithId(_ id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Annotations API

    func fetchAnnotationsForAttachmentWithId(_ id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)/annotations", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createAnnotationForAttachmentWithId(_ id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)/annotations", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAnnotationWithId(_ id: String, forAttachmentWithId attachmentId: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(attachmentId)/annotations/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createAnnotationForFloorplanWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(id)/annotations", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAnnotationWithId(_ id: String, forFloorplanWithId floorplanId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(floorplanId)/annotations/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Company API

    func fetchCompanies(_ params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("companies", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Invitation API

    func fetchInvitationWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("invitations/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    // MARK: User API

    func createUser(_ params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                let userToken = mappingResult?.firstObject as! UserToken
                if let token = userToken.token {
                    token.user = userToken.user
                    self.setToken(token)
                }
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func fetchUser(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users/\(currentUser().id)", method: .GET, params: [:],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200)
                let user = mappingResult?.firstObject as! User
                if let token = KeyChainService.sharedService().token {
                    token.user = user
                    KeyChainService.sharedService().token = token
                }
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func updateUser(_ params: [String: String], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users/\(currentUser().id)", method: .PUT, params: params as [String : AnyObject]?,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 204)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func setUserDefaultProfileImage(_ image: UIImage, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let params = [
            "public": false,
            "tags": ["profile_image", "default"]
        ] as [String : Any]

        let data = UIImageJPEGRepresentation(image, 1.0)

        ApiService.sharedService().addAttachment(data!,
            withMimeType: "image/jpg",
            toUserWithId: String(currentUser().id),
            params: params as [String : AnyObject],
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode, mappingResult)

                ApiService.sharedService().fetchUser(
                    onSuccess: { statusCode, mappingResult in
                        if !UIApplication.shared.isRegisteredForRemoteNotifications {
                            NotificationCenter.default.postNotificationName("ProfileImageShouldRefresh")
                        }
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, usingPresignedS3RequestURL presignedS3RequestURL: URL, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var metadata = [String : String]()
        if let tags = params["tags"] {
            metadata["tags"] = (tags as! [String]).joined(separator: ",")
        }
        KTS3Service.presign(presignedS3RequestURL, filename: "upload.\(mimeMappings[mimeType]!)", metadata: metadata, headers: self.headers,
            successHandler: { object in
                let response = try? JSONSerialization.jsonObject(with: (object! as! NSData) as Data, options: [])
                let map = Map(mappingType: .fromJSON,
                    JSON: response as! [String : AnyObject],
                    toObject: true,
                    context: nil)

                let presignedRequest = KTPresignedS3Request()
                presignedRequest.mapping(map: map)

                KTS3Service.upload(presignedRequest, data: data, withMimeType: mimeType,
                    successHandler: { object in
                        var realParams = params
                        realParams.updateValue(presignedRequest.fields!["key"]! as AnyObject, forKey: "key")
                        realParams.updateValue(mimeType as AnyObject, forKey: "mime_type")

                        let url = "\(presignedRequest.url)\(presignedRequest.fields!["key"]!)"
                        realParams.updateValue(url as AnyObject, forKey: "url")

                        let createAttachmentUri = presignedS3RequestURL.path.replaceString("/api/", withString: "").replaceString("/attachments/new", withString: "/attachments")
                        let _ = self.dispatchApiOperationForPath(createAttachmentUri, method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
                    },
                    failureHandler: { response, object, error in
                        onError(error!, (response?.statusCode)!, object! as! String)
                    }
                )
            },
            failureHandler: { response, object, error in
                onError(error!, (response?.statusCode)!, object! as! String)
            }
        )
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toUserWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/users/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(_ id: String, onUserWithId userId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users/\(userId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Device API

    func createDevice(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("devices", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func deleteDeviceWithId(_ deviceId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("devices/\(deviceId)", method: .DELETE, params: nil, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Remote notifications

    func registerForRemoteNotifications() {
        if !isSimulator() {
            NotificationCenter.default.postNotificationName("ApplicationWillRegisterUserNotificationSettings")

            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.sound, UIUserNotificationType.alert]
            let settings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }

    func unregisterForRemoteNotifications() {
        if !isSimulator() {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }

    // MARK: Category API

    func countCategories(_ params: [String: AnyObject], onTotalResultsCount: @escaping OnTotalResultsCount) {
        countTotalResultsForPath("categories", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchCategories(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("categories", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Customer API

    func countCustomers(_ params: [String: AnyObject], onTotalResultsCount: @escaping OnTotalResultsCount) -> RKObjectRequestOperation! {
        return countTotalResultsForPath("customers", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchCustomers(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("customers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchCustomerWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("customers/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    // MARK: Provider API

    @discardableResult
    func countProviders(_ params: [String : AnyObject], onTotalResultsCount: @escaping OnTotalResultsCount) -> RKObjectRequestOperation! {
        return countTotalResultsForPath("providers", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    @discardableResult
    func fetchProviders(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("providers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("providers/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderAvailability(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("providers/\(id)/availability", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createProvider(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("providers", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateProviderWithId(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["customerId"] = nil

        dispatchApiOperationForPath("providers/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Checkin API

    func checkin(_ location: CLLocation) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let checkinDate = dateFormatter.string(from: location.timestamp)

        let longitude = location.coordinate.longitude
        let latitude = location.coordinate.latitude

        let params: [String: AnyObject] = ["latitude": latitude as AnyObject, "longitude": longitude as AnyObject, "checkin_at": checkinDate as AnyObject]

        return checkin(params,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func checkin(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("checkins", method: .POST, params: params,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    // MARK: Task API

    func fetchTaskWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tasks/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchTaskWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tasks/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchTasks(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tasks", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createTask(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["userId"] = nil

        dispatchApiOperationForPath("tasks", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateTaskWithId(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["userId"] = nil

        dispatchApiOperationForPath("tasks/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Work order API

    func fetchWorkOrderWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrderWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrders(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createWorkOrder(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["customer"] = nil
        realParams["companyId"] = nil
        realParams["customerId"] = nil

        dispatchApiOperationForPath("work_orders", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateWorkOrderWithId(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["company"] = nil
        realParams["customer"] = nil
        realParams["companyId"] = nil
        realParams["customerId"] = nil

        dispatchApiOperationForPath("work_orders/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forWorkOrderWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toWorkOrderWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/work_orders/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(_ id: String, onWorkOrderWithId workOrderId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(workOrderId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Comments API

    func fetchCommentWithId(_ id: String, forCommentableType commentableType: String, withCommentableId commentableId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(commentableType)s/\(commentableId)/comments/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchComments(_ params: [String : AnyObject], forCommentableType commentableType: String, withCommentableId commentableId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(commentableType)s/\(commentableId)/comments", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchComments(forJobWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)/comments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addComment(_ comment: String, toJobWithId id: String!, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)/comments", method: .POST, params: ["body": comment as AnyObject],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func fetchComments(forWorkOrderWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/comments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addComment(_ comment: String, toWorkOrderWithId id: String!, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/comments", method: .POST, params: ["body": comment as AnyObject],
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 201)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toCommentWithId id: String, forCommentableType commentableType: String, withCommentableId commentableId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/\(commentableType)s/\(commentableId)/comments/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Products API

    func countProducts(_ params: [String : AnyObject], onTotalResultsCount: @escaping OnTotalResultsCount) {
        countTotalResultsForPath("products", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    func fetchProducts(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation! {
        return dispatchApiOperationForPath("products", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createProduct(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("products", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateProductWithId(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("products/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Route API

    func fetchRoutes(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("routes", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchRouteWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("routes/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateRouteWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams.removeValue(forKey: "id")

        dispatchApiOperationForPath("routes/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Directions and Routing API

    func getDrivingDirectionsFromCoordinate(_ coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions", method: .GET, params: params as [String : AnyObject]?,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200 || statusCode == 304)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    func getDrivingEtaFromCoordinate(_ coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions/eta", method: .GET, params: params as [String : AnyObject]?,
            onSuccess: { statusCode, mappingResult in
                assert(statusCode == 200 || statusCode == 304)
                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }

    // MARK: Floorplans API

    func fetchFloorplans(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchFloorplans(forJobWithId jobId: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(jobId)/floorplans", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchFloorplanWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchFloorplanWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createFloorplan(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("floorplans", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateFloorplanWithId(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("floorplans/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrders(forFloorplanWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(id)/work_orders", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchAnnotationsForFloorplanWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(id)/annotations", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forFloorplanWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toFloorplanWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/floorplans/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachmentFromSourceUrl(_ sourceUrl: URL, toFloorplanWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = params
        params["source_url"] = sourceUrl.absoluteString as AnyObject
        dispatchApiOperationForPath("floorplans/\(id)/attachments", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(_ id: String, onFloorplanWithId floorplanId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("floorplans/\(floorplanId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Jobs API

    func fetchJobs(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchJobWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchJobWithId(_ id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createJob(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
//        realParams["companyId"] = nil

        dispatchApiOperationForPath("jobs", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateJobWithId(_ id: String, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("jobs/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forJobWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toJobWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/jobs/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachmentFromSourceUrl(_ sourceUrl: URL, toJobWithId id: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = params
        params["source_url"] = sourceUrl.absoluteString as AnyObject
        dispatchApiOperationForPath("jobs/\(id)/attachments", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(_ id: String, onJobWithId jobId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(jobId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Estimates API

    func fetchEstimates(forJobWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)/estimates", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchEstimateWithId(_ id: String, forJobWithId jobId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func createEstimate(_ params: [String : AnyObject], forJobWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)/estimates", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachmentFromSourceUrl(_ sourceUrl: URL, toEstimateWithId id: String, forJobWithId jobId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = params
        params["source_url"] = sourceUrl.absoluteString as AnyObject
        dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(id)/attachments", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toEstimateWithId id: String, forJobWithId jobId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/estimates/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    func updateAttachmentWithId(_ id: String, forEstimateWithId estimateId: String, onJobWithId jobId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(jobId)/estimates/\(estimateId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Expenses API

    func fetchExpenses(forJobWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("jobs/\(id)/expenses", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchExpenses(forWorkOrderWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/expenses", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func createExpense(_ params: [String : AnyObject], forExpensableType expensableType: String, withExpensableId expensableId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(expensableType)s/\(expensableId)/expenses", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toExpenseWithId id: String, forExpensableType expensableType: String, withExpensableId expensableId: String, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/\(expensableType)s/\(expensableId)/expenses/\(id)/attachments/new")!
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: - Messages API

    func fetchMessages(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("messages", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createMessage(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("messages", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Private methods

    @discardableResult
    fileprivate func countTotalResultsForPath(_ path: String, params: [String : AnyObject], onTotalResultsCount: @escaping OnTotalResultsCount) -> RKObjectRequestOperation! {
        var params = params

        params["page"] = 1 as AnyObject
        params["rpp"] = 0 as AnyObject

        let op = dispatchApiOperationForPath(path, method: .GET, params: params, startOperation: false,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )

        if let op = op {
            op.setCompletionBlockWithSuccess(
                { operation, mappingResult in
                    if self.requestOperations.contains(op) {
                        self.requestOperations.removeObject(op)
                    }

                    let headers = operation?.httpRequestOperation.response.allHeaderFields
                    if let totalResultsCountString = headers?["X-Total-Results-Count"] as? String {
                        if let totalResultsCount = Int(totalResultsCountString) {
                            onTotalResultsCount(totalResultsCount, nil)
                        }
                    }
                },

                failure: { operation, error in
                    if self.requestOperations.contains(op) {
                        self.requestOperations.removeObject(op)
                    }

                    onTotalResultsCount(-1, error as NSError?)
                }
            )
            
            op.start()
            requestOperations.append(op)

            return op
        }

        return nil
    }

    @discardableResult
    fileprivate func dispatchApiOperationForPath(_ path: String,
                                             method: RKRequestMethod! = .GET,
                                             params: [String: AnyObject]?,
                                             startOperation: Bool = true,
                                             onSuccess: @escaping OnSuccess,
                                             onError: @escaping OnError) -> RKObjectRequestOperation! {
        return dispatchOperationForURL(URL(string: CurrentEnvironment.baseUrlString)!,
                                       path: "api/\(path)",
                                       method: method,
                                       params: params,
                                       contentType: "application/json",
                                       startOperation: startOperation,
                                       onSuccess: onSuccess,
                                       onError: onError)
    }

    fileprivate func objectMappingForPath(_ path: String, method: String) -> RKObjectMapping? {
        var path = path
        let parts = path.characters.split(separator: "/").map { String($0) }
        if parts.count > 5 {
            path = [parts[3], parts[5]].joined(separator: "/")
            path = path.components(separatedBy: "/").last!
        } else if parts.count > 3 {
            path = [parts[1], parts[3]].joined(separator: "/")
            path = path.components(separatedBy: "/").last!
        } else {
            path = parts[1]
        }

        var mapping: RKObjectMapping?

        if let object = objectMappings[path] {
            if object is RKObjectMapping {
                mapping = object as? RKObjectMapping
            } else if object is [String : RKObjectMapping] {
                for entry in (object as! [String : RKObjectMapping]).enumerated() {
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

    @discardableResult
    fileprivate func dispatchOperationForURL(_ baseURL: URL,
                                         path: String,
                                         method: RKRequestMethod = .GET,
                                         params: [String : AnyObject]!,
                                         contentType: String = "application/json",
                                         startOperation: Bool = true,
                                         onSuccess: @escaping OnSuccess,
                                         onError: @escaping OnError) -> RKObjectRequestOperation! {
        var responseMapping = objectMappingForPath(path, method: RKStringFromRequestMethod(method).lowercased())
        if responseMapping == nil {
            responseMapping = RKObjectMapping(for: nil)
        }

        if let responseDescriptor = RKResponseDescriptor(mapping: responseMapping, method: method, pathPattern: nil, keyPath: nil, statusCodes: nil) {
            var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if method == .GET && params.count > 0 {
                urlComponents.query = params.toQueryString()
            }

            let request = NSMutableURLRequest(url: urlComponents.url!)
            request.httpMethod = RKStringFromRequestMethod(method)
            request.httpShouldHandleCookies = false
            request.setValue("application/json", forHTTPHeaderField: "accept")

            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }

            var jsonParams = "{}"

            if [.POST, .PUT].contains(method) {
                request.setValue(contentType, forHTTPHeaderField: "content-type")

                if let _ = params {
                    if contentType.lowercased() == "application/json" {
                        jsonParams = NSDictionary(dictionary: params).toJSON()
                        request.httpBody = jsonParams.data(using: String.Encoding.utf8)
                    }
                }
            }

            if let op = RKObjectRequestOperation(request: request as URLRequest!, responseDescriptors: [responseDescriptor]) {
                let startDate = Date()

                op.setCompletionBlockWithSuccess(
                    { operation, mappingResult in
                        AnalyticsService.sharedService().track("HTTP Request Succeeded", properties: ["path": path as AnyObject,
                                                                                                      "statusCode": (operation?.httpRequestOperation.response.statusCode)! as AnyObject,
                                                                                                      "params": jsonParams as AnyObject,
                                                                                                      "execTimeMillis": (NSDate().timeIntervalSince(startDate) * 1000.0) as AnyObject] as [String : AnyObject])

                        if self.requestOperations.contains(op) {
                            self.requestOperations.removeObject(op)
                        }

                        onSuccess((operation?.httpRequestOperation.response.statusCode)!,
                                  mappingResult)
                    },
                    failure: { operation, error in
                        let receivedResponse = operation?.httpRequestOperation.response != nil
                        let responseString = receivedResponse ? (operation?.httpRequestOperation.responseString)! : "{}"
                        let statusCode = receivedResponse ? (operation?.httpRequestOperation.response.statusCode)! : -1

                        if receivedResponse {
                            self.backoffTimeout = self.initialBackoffTimeout

                            AnalyticsService.sharedService().track("HTTP Request Failed", properties: ["path": path as AnyObject,
                                                                                                       "statusCode": statusCode as AnyObject,
                                                                                                       "params": jsonParams as AnyObject,
                                                                                                       "responseString": responseString as AnyObject,
                                                                                                       "execTimeMillis": (NSDate().timeIntervalSince(startDate) * 1000.0) as AnyObject] as [String : AnyObject])

                            if statusCode == 401 {
                                if baseURL.absoluteString == CurrentEnvironment.baseUrlString {
                                    self.forceLogout()
                                }
                            }
                        } else if let err = error as NSError? {
                            AnalyticsService.sharedService().track("HTTP Request Failed", properties: ["error": err.localizedDescription as AnyObject,
                                                                                                       "code": err.code as AnyObject,
                                                                                                       "params": jsonParams as AnyObject,
                                                                                                       "execTimeMillis": (NSDate().timeIntervalSince(startDate) * 1000.0) as AnyObject] as [String : AnyObject])

                            DispatchQueue.global(qos: DispatchQoS.default.qosClass).asyncAfter(deadline: .now() + Double(Int64(self.backoffTimeout * Double(NSEC_PER_SEC)))) {
                                let _ = self.dispatchOperationForURL(baseURL,
                                                                     path: path,
                                                                     method: method,
                                                                     params: params,
                                                                     onSuccess: onSuccess,
                                                                     onError: onError)
                            }

                            self.backoffTimeout = self.backoffTimeout > 60.0 ? self.initialBackoffTimeout : self.backoffTimeout * 2
                        }

                        if self.requestOperations.contains(op) {
                            self.requestOperations.removeObject(op)
                        }

                        onError(error! as NSError,
                                statusCode,
                                responseString)
                    }
                )

                if startOperation {
                    op.start()
                    self.requestOperations.append(op)
                }
                
                return op
            }
        }

        return nil
    }
}
