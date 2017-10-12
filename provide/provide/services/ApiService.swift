//
//  ApiService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import JWTDecode

typealias OnSuccess = (_ statusCode: Int, _ mappingResult: RKMappingResult?) -> Void
typealias OnError = (_ error: NSError, _ statusCode: Int, _ responseString: String) -> Void
typealias OnURLFetched = (_ statusCode: Int, _ response: Data) -> Void
typealias OnImageFetched = (_ statusCode: Int, _ response: UIImage) -> Void
typealias OnTotalResultsCount = (_ totalResultsCount: Int, _ error: NSError?) -> Void

let presignedS3RequestURL = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/s3/presign")!

class ApiService: NSObject {
    static let shared = ApiService()

    private let mimeMappings = [
        "application/pdf": "pdf",
        "image/jpg": "jpg",
        "image/jpeg": "jpg",
        "image/x-dwg": "dwg",
        "video/mp4": "m4v",
    ]

    private static let usersMapping = ["*": User.mapping(), "post": UserToken.mapping()]

    private let objectMappings: [String: Any] = [
        "attachments": Attachment.mappingWithRepresentations(),
        "devices": Device.mapping(),
        "directions": Directions.mapping(),
        "eta": Directions.mapping(),
        "invitations": Invitation.mapping(),
        "places": Contact.mapping(),
        "providers": Provider.mapping(),
        "tokens": Token.mapping(),
        "work_orders": WorkOrder.mapping(),
        "users": ApiService.usersMapping,
        "messages": Message.mapping(),
    ]

    private let initialBackoffTimeout: TimeInterval = 0.1
    private var backoffTimeout: TimeInterval!

    private var headers = [String: String]()

    private var requestOperations = [RKObjectRequestOperation]()

    override init() {
        super.init()

        backoffTimeout = initialBackoffTimeout

        if let token = KeyChainService.shared.token {
            headers["X-API-Authorization"] = token.authorizationHeaderString
        }
    }

    // MARK: Token API

    var hasCachedToken: Bool {
        if let token = KeyChainService.shared.token {
            let hasCachedToken = token.user != nil
            if !hasCachedToken {
                KeyChainService.shared.token = nil
            }
            return hasCachedToken
        }

        return false
    }

    private func setToken(_ token: Token) {
        headers["X-API-Authorization"] = token.authorizationHeaderString
        KeyChainService.shared.token = token

        if let user = token.user {
            KeyChainService.shared.email = user.email
            AnalyticsService.shared.identify(user)
        }

        registerForRemoteNotifications()

        NotificationService.shared.connectWebsocket()
    }

    func login(_ jwt: JWT) -> Bool {
        let tokenId = jwt.body["token_id"] as? Int
        let token = jwt.body["token"] as? String
        let uuid = jwt.body["token_uuid"] as? String
        let userId = jwt.body["user_id"] as? Int
        let userEmail = jwt.body["email"] as? String
        let userName = jwt.body["name"] as? String

        if let tokenId = tokenId, let token = token, let uuid = uuid, let userId = userId, let userEmail = userEmail, let userName = userName {
            let t = Token()
            t.id = tokenId
            t.token = token
            t.uuid = uuid

            let user = User()
            user.id = userId
            user.email = userEmail
            user.name = userName
            t.user = user

            currentUser = user
            setToken(t)

            return true
        }

        return false
    }

    func login(_ params: [String: String], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tokens", method: .POST, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 201)
            let token = mappingResult?.firstObject as! Token
            self.setToken(token)
            onSuccess(statusCode, mappingResult)
        }, onError: { error, statusCode, responseString in
            onError(error, statusCode, responseString)
            KeyChainService.shared.clearStoredUserData()
        })
    }

    func logout(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if !isSimulator() {
            unregisterForRemoteNotifications()
        }

        deleteToken(onSuccess: onSuccess, onError: onError)
    }

    private func forceLogout() {
        if !isSimulator() {
            unregisterForRemoteNotifications()
        }

        localLogout()

        NotificationCenter.default.postNotificationName("ApplicationUserLoggedOut")
    }

    private func deleteToken(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if let token = KeyChainService.shared.token {
            dispatchApiOperationForPath("tokens/\(token.id)", method: .DELETE, params: nil, onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode, mappingResult)
                self.localLogout()
            }, onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
                self.localLogout()
            })
        }
    }

    private func localLogout() {
        CheckinService.shared.stop()
        LocationService.shared.stop()
        NotificationService.shared.disconnectWebsocket()
        headers.removeValue(forKey: "X-API-Authorization")
        KeyChainService.shared.clearStoredUserData()
        AnalyticsService.shared.logout()
        ImageService.shared.clearCache()

        currentUser = nil
        backoffTimeout = nil
    }

    // MARK: Fetch images

    func fetchURL(_ url: URL, onURLFetched: @escaping OnURLFetched, onError: OnError) {
        let params = url.query != nil ? url.query!.toJSONObject() : [:]
        let request = Alamofire.request(url.absoluteString, method: .get, parameters: params)
        KTApiService.shared.execute(request, successHandler: { response in
            let statusCode = response!.response!.statusCode
            onURLFetched(statusCode, response!.responseData)
        }, failureHandler: { response, statusCode, error in

        })
    }

    // MARK: Attachments API

    private func createAttachment(_ attachableType: String, withAttachableId attachableId: String, params: [String: Any], onSuccess: @escaping KTApiSuccessHandler, onError: @escaping KTApiFailureHandler) {
        dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments", method: .POST, params: params, onSuccess: { statusCode, response in
            onSuccess(response)
        }, onError: { resp, obj, err in
            logWarn("Failed to create \(attachableType) attachment")
        })
    }

    func updateAttachmentWithId(_ id: String, forAttachableType attachableType: String, withAttachableId attachableId: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("\(attachableType)s/\(attachableId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError )
    }

    private func addAttachment(_ data: Data, withMimeType mimeType: String, usingPresignedS3RequestURL presignedS3RequestURL: URL, params: [String: Any], onSuccess: @escaping KTApiSuccessHandler, onError: @escaping KTApiFailureHandler) {
        var tags: String! = nil
        if let t = params["tags"] as? [String] {
            tags = t.joined(separator: ",")
        }
        let metadata = [
            "sqs-queue-url": "https://sqs.us-east-1.amazonaws.com/562811387569/prvd-production",
            "tags": tags,
        ] as [String: Any]

        KTS3Service.presign(presignedS3RequestURL, bucket: nil, filename: "upload.\(mimeMappings[mimeType]!)", metadata: metadata as! [String : String], headers: headers, successHandler: { object in
            let presignResponse = try? JSONSerialization.jsonObject(with: (object! as! NSData) as Data, options: [])
            let map = Map(mappingType: .fromJSON,
                          JSON: presignResponse as! [String: Any],
                          toObject: true,
                          context: nil)

            let presignedRequest = KTPresignedS3Request()
            presignedRequest.mapping(map: map)

            KTS3Service.upload(presignedRequest, data: data, withMimeType: mimeType, successHandler: { _ in
                logInfo("Attachment uploaded to S3")
                onSuccess(presignResponse as AnyObject)
            }, failureHandler: { resp, obj, err in
                logWarn("Failed to upload attachment to S3")
                onError(resp, obj, err)
            })
        }, failureHandler: { resp, code, err in
            logWarn("Failed to presign S3")
        })
    }

    private func addAttachment(_ data: Data, withMimeType mimeType: String, toUserWithId id: String, params: [String: Any], onSuccess: @escaping KTApiSuccessHandler, onError: @escaping KTApiFailureHandler) {
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: { response in
            var attachment = [String: Any]()
            if let response = response as? [String: Any] {
                let bucketBaseUrl = response["url"] as? String
                if let fields = response["fields"] as? [String: Any] {
                    if let key = fields["key"] as? String {
                        let url = "\(bucketBaseUrl!)/\(key)"
                        attachment["url"] = url
                        attachment["key"] = key
                    }
                    if let mimeType = fields["Content-Type"] {
                        attachment["mime_type"] = mimeType
                    }
                    attachment["metadata"] = fields
                }
            }
            for (k, v) in params {
                attachment[k] = v
            }
            self.createAttachment("user", withAttachableId: id, params: attachment, onSuccess: onSuccess, onError: onError)
        }, onError: onError)
    }

    private func updateAttachmentWithId(_ id: String, onUserWithId userId: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users/\(userId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError )
    }

    // MARK: Invitation API

    func fetchInvitationWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("invitations/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    // MARK: User API

    func createUser(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users", method: .POST, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 201)
            let userToken = mappingResult?.firstObject as! UserToken
            if let token = userToken.token {
                token.user = userToken.user
                self.setToken(token)
            }
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    func fetchUser(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users/\(currentUser.id)", method: .GET, params: [:], onSuccess: { statusCode, mappingResult in
            assert(statusCode == 200)
            let user = mappingResult?.firstObject as! User
            if let token = KeyChainService.shared.token {
                currentUser = user
                token.user = user
                KeyChainService.shared.token = token
            }
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    func updateUser(_ params: [String: String], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("users/\(currentUser.id)", method: .PUT, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 204)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    func setUserDefaultProfileImage(_ image: UIImage, onSuccess: @escaping KTApiSuccessHandler, onError: @escaping KTApiFailureHandler) {
        let params = [
            "public": true,
            "tags": ["profile_image", "default"],
        ] as [String: Any]

        let data = UIImageJPEGRepresentation(image, 1.0)

        ApiService.shared.addAttachment(data!, withMimeType: "image/jpg", toUserWithId: String(currentUser.id), params: params, onSuccess: { response in
            onSuccess(response)

            ApiService.shared.fetchUser(onSuccess: { statusCode, mappingResult in
                if !UIApplication.shared.isRegisteredForRemoteNotifications {
                    NotificationCenter.default.postNotificationName("ProfileImageShouldRefresh")
                }
            }, onError: { error, statusCode, responseString in
                logWarn("Failed to fetch user (\(statusCode))")
            })
        }, onError: onError)
    }

    // MARK: Device API

    func createDevice(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("devices", method: .POST, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 201)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    private func deleteDeviceWithId(_ deviceId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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

    private func unregisterForRemoteNotifications() {
        if !isSimulator() {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }

    // MARK: Category API

    private func countCategories(_ params: [String: Any], onTotalResultsCount: @escaping OnTotalResultsCount) {
        countTotalResultsForPath("categories", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    private func fetchCategories(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("categories", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Provider API

    @discardableResult
    private func countProviders(_ params: [String: Any], onTotalResultsCount: @escaping OnTotalResultsCount) -> RKObjectRequestOperation? {
        return countTotalResultsForPath("providers", params: params, onTotalResultsCount: onTotalResultsCount)
    }

    @discardableResult
    func fetchProviders(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation? {
        return dispatchApiOperationForPath("providers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("providers/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    private func fetchProviderAvailability(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("providers/\(id)/availability", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createProvider(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("providers", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateProviderWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("providers/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Checkin API

    func checkin(_ location: CLLocation, heading: CLHeading!) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let checkinDate = dateFormatter.string(from: location.timestamp)

        let longitude = location.coordinate.longitude
        let latitude = location.coordinate.latitude

        var params: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "checkin_at": checkinDate,
        ]

        if let heading = heading {
            params["heading"] = heading.magneticHeading
        }

        return checkin(params, onSuccess: { statusCode, mappingResult in
            logInfo("Checkin succeeded; \(mappingResult!)")
        }, onError: { error, statusCode, responseString in
            logWarn("Checkin failed (\(statusCode))")
        })
    }

    private func checkin(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("checkins", method: .POST, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 201)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    // MARK: Task API

    private func fetchTaskWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tasks/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    private func fetchTaskWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tasks/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func fetchTasks(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("tasks", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func createTask(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["userId"] = nil

        dispatchApiOperationForPath("tasks", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    private func updateTaskWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil
        realParams["userId"] = nil

        dispatchApiOperationForPath("tasks/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Work order API

    private func fetchWorkOrderWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrderWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchWorkOrders(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createWorkOrder(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("work_orders", method: .POST, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func updateWorkOrderWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams["id"] = nil

        dispatchApiOperationForPath("work_orders/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    func fetchAttachments(forWorkOrderWithId id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(id)/attachments", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    func addAttachment(_ data: Data, withMimeType mimeType: String, toWorkOrderWithId id: String, params: [String: Any], onSuccess: @escaping KTApiSuccessHandler, onError: @escaping KTApiFailureHandler) {
        addAttachment(data, withMimeType: mimeType, usingPresignedS3RequestURL: presignedS3RequestURL, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func updateAttachmentWithId(_ id: String, onWorkOrderWithId workOrderId: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("work_orders/\(workOrderId)/attachments/\(id)", method: .PUT, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Route API

    private func fetchRoutes(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("routes", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func fetchRouteWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("routes/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func updateRouteWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var realParams = params
        realParams.removeValue(forKey: "id")

        dispatchApiOperationForPath("routes/\(id)", method: .PUT, params: realParams, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Directions, Routing and Places APIs

    func getDrivingDirectionsFromCoordinate(_ coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions", method: .GET, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 200 || statusCode == 304)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    func getDrivingEtaFromCoordinate(_ coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let params = ["from_latitude": coordinate.latitude, "from_longitude": coordinate.longitude, "to_latitude": toCoordinate.latitude, "to_longitude": toCoordinate.longitude]

        dispatchApiOperationForPath("directions/eta", method: .GET, params: params, onSuccess: { statusCode, mappingResult in
            assert(statusCode == 200 || statusCode == 304)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    @discardableResult
    func autocompletePlaces(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation? {
        return dispatchApiOperationForPath("directions/places", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: - Payment methods API

    private func fetchPaymentMethods(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("payment_methods", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    private func createPaymentMethod(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("payment_methods", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: - Messages API

    func fetchMessages(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("messages", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func createMessage(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("messages", method: .POST, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Private methods

    @discardableResult
    private func countTotalResultsForPath(_ path: String, params: [String: Any], onTotalResultsCount: @escaping OnTotalResultsCount) -> RKObjectRequestOperation? {
        var params = params

        params["page"] = 1
        params["rpp"] = 0

        let op = dispatchApiOperationForPath(path, method: .GET, params: params, startOperation: false, onSuccess: { statusCode, mappingResult in
            // TODO
        }, onError: { error, statusCode, responseString in
            logError(error)
        })

        if let op = op {
            op.setCompletionBlockWithSuccess({ operation, mappingResult in
                if self.requestOperations.contains(op) {
                    self.requestOperations.removeObject(op)
                }

                let headers = operation?.httpRequestOperation.response.allHeaderFields
                if let totalResultsCountString = headers?["X-Total-Results-Count"] as? String, let totalResultsCount = Int(totalResultsCountString) {
                    onTotalResultsCount(totalResultsCount, nil)
                }
            }, failure: { operation, error in
                if self.requestOperations.contains(op) {
                    self.requestOperations.removeObject(op)
                }

                onTotalResultsCount(-1, error as NSError?)
            })

            op.start()
            requestOperations.append(op)

            return op
        }

        return nil
    }

    @discardableResult
    private func dispatchApiOperationForPath(_ path: String, method: RKRequestMethod! = .GET, params: [String: Any]?, startOperation: Bool = true, onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation? {
        return dispatchOperationForURL(URL(string: CurrentEnvironment.baseUrlString)!, path: "api/\(path)", method: method, params: params, contentType: "application/json", startOperation: startOperation, onSuccess: onSuccess, onError: onError)
    }

    private func objectMappingForPath(_ path: String, method: String) -> RKObjectMapping? {
        var path = path
        let parts = path.characters.split(separator: "/").map { String($0) }
        if parts.count > 5 {
            path = [parts[3], parts[5]].joined(separator: "/")
            path = path.components(separatedBy: "/").last!
        } else if parts.count > 3 {
            path = [parts[1], parts[3]].joined(separator: "/")
            path = path.components(separatedBy: "/").last!
        } else {
            if Int(parts.last!) != nil {
                path = parts[1]
            } else {
                path = parts.last!
            }
        }

        var mapping: RKObjectMapping?

        if let object = objectMappings[path] {
            if object is RKObjectMapping {
                mapping = object as? RKObjectMapping
            } else if object is [String: RKObjectMapping] {
                for entry in (object as! [String: RKObjectMapping]).enumerated() {
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
    private func dispatchOperationForURL(_ baseURL: URL, path: String, method: RKRequestMethod = .GET, params: [String: Any]?, contentType: String = "application/json", startOperation: Bool = true, onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> RKObjectRequestOperation? {
        var responseMapping = objectMappingForPath(path, method: RKStringFromRequestMethod(method).lowercased())
        if responseMapping == nil {
            responseMapping = RKObjectMapping(for: nil)
        }

        if let responseDescriptor = RKResponseDescriptor(mapping: responseMapping, method: method, pathPattern: nil, keyPath: nil, statusCodes: nil) {
            var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if method == .GET && params?.isEmpty == false {
                urlComponents.query = params?.toQueryString()
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

                if let params = params, contentType.lowercased() == "application/json" {
                    jsonParams = NSDictionary(dictionary: params).toJSON()
                    request.httpBody = jsonParams.data(using: .utf8)
                }
            }

            if let op = RKObjectRequestOperation(request: request as URLRequest!, responseDescriptors: [responseDescriptor]) {
                let startDate = Date()

                op.setCompletionBlockWithSuccess({ operation, mappingResult in
                    AnalyticsService.shared.track("HTTP Request Succeeded", properties: [
                        "path": path,
                        "statusCode": (operation?.httpRequestOperation.response.statusCode)!,
                        "params": jsonParams,
                        "execTimeMillis": (NSDate().timeIntervalSince(startDate) * 1000.0),
                    ])

                    if self.requestOperations.contains(op) {
                        self.requestOperations.removeObject(op)
                    }

                    if ProcessInfo.processInfo.environment["WRITE_JSON_RESPONSES"] != nil {
                        JSONResponseWriter.writeResponseToFile(operation!)
                    }

                    onSuccess((operation?.httpRequestOperation.response.statusCode)!, mappingResult)
                }, failure: { operation, error in
                    let receivedResponse = operation?.httpRequestOperation.response != nil
                    let responseString = receivedResponse ? (operation?.httpRequestOperation.responseString)! : "{}"
                    let statusCode = receivedResponse ? (operation?.httpRequestOperation.response.statusCode)! : -1

                    if receivedResponse {
                        self.backoffTimeout = self.initialBackoffTimeout

                        AnalyticsService.shared.track("HTTP Request Failed", properties: [
                            "path": path,
                            "statusCode": statusCode,
                            "params": jsonParams,
                            "responseString": responseString,
                            "execTimeMillis": (NSDate().timeIntervalSince(startDate) * 1000.0),
                        ])

                        if statusCode == 401 {
                            if baseURL.absoluteString == CurrentEnvironment.baseUrlString {
                                self.forceLogout()
                            }
                        }
                    } else if let err = error as NSError? {
                        AnalyticsService.shared.track("HTTP Request Failed", properties: [
                            "error": err.localizedDescription,
                            "code": err.code,
                            "params": jsonParams,
                            "execTimeMillis": (NSDate().timeIntervalSince(startDate) * 1000.0),
                        ])

                        DispatchQueue.global(qos: DispatchQoS.default.qosClass).asyncAfter(deadline: .now() + Double(Int64(self.backoffTimeout * Double(NSEC_PER_SEC)))) {
                            _ = self.dispatchOperationForURL(baseURL, path: path, method: method, params: params, onSuccess: onSuccess, onError: onError)
                        }

                        self.backoffTimeout = self.backoffTimeout > 60.0 ? self.initialBackoffTimeout : self.backoffTimeout * 2
                    }

                    if self.requestOperations.contains(op) {
                        self.requestOperations.removeObject(op)
                    }

                    onError(error! as NSError, statusCode, responseString)
                })

                if startOperation {
                    op.start()
                    requestOperations.append(op)
                }

                return op
            }
        }

        return nil
    }
}
