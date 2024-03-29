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
import FBSDKLoginKit

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
        "categories": Category.mapping(),
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

    private var headers = [String: String]()

    private var opDispatchQueue: DispatchQueue!
    private var opQueue: OperationQueue!
    private var urlSession: URLSession!

    private var multipathTcpEnabled: Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }

    override init() {
        super.init()

        configureUrlSession()

        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: .reachabilityChanged, object: nil)

        KTNotificationCenter.addObserver(forName: .ApplicationShouldForceLogout) { [weak self] notification in
            logInfo("Received ApplicationShouldForceLogout notification")
            self?.forceLogout()
        }

        if let token = KeyChainService.shared.token {
            headers["X-API-Authorization"] = token.authorizationHeaderString
        }
    }

    private func configureUrlSession() {
        opDispatchQueue = DispatchQueue(label: "urlOperationsQueue", attributes: .concurrent)

        opQueue = OperationQueue()
        opQueue.underlyingQueue = opDispatchQueue

        let sessionConfig = URLSessionConfiguration.ephemeral
        if #available(iOS 11.0, *) {
            sessionConfig.multipathServiceType = .interactive
        }

        urlSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: opQueue)
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

        KTNotificationCenter.post(name: .ApplicationUserLoggedOut)
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

        opQueue.cancelAllOperations()

        currentUser = nil

        if FBSDKAccessToken.current() != nil {
            FBSDKLoginManager().logOut()
        }
    }

    private func cancelAllOperations() {
        DispatchQueue.global(qos: DispatchQoS.default.qosClass).async { [weak self] in
            logInfo("Canceling all inflight API operations due to reachability change")
            let idempotentOperations = self?.opQueue?.operations.filter { ($0 as! ApiOperation).isIdempotent }
            self?.opQueue?.cancelAllOperations()
            self?.opQueue?.waitUntilAllOperationsAreFinished()

            logInfo("Suspending API operations due to reachability change")
            self?.opDispatchQueue?.suspend()

            if let idempotentOperations = idempotentOperations {
                logInfo("Requeueing \(idempotentOperations.count) cancelled idempotent API operations")
                idempotentOperations.forEach({ self?.dispatchApiOperation($0 as! ApiOperation) })
                self?.opQueue?.addOperations(idempotentOperations, waitUntilFinished: false)
            }
        }
    }

    @objc private func reachabilityChanged(_ notification: NSNotification) {
        if !ReachabilityService.shared.reachability.isReachable() {
            if !multipathTcpEnabled {
                cancelAllOperations()
            }
        } else if !multipathTcpEnabled {
            logInfo("Resuming API operations due to reachability change")
            if opQueue?.isSuspended ?? false {
                opDispatchQueue?.resume()
            }
        }
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
        var tags = ""
        if let t = params["tags"] as? [String] {
            tags = t.joined(separator: ",")
        }
        let metadata = [
            "sqs-queue-url": "https://sqs.us-east-1.amazonaws.com/562811387569/prvd-production",
            "tags": tags,
        ]

        KTS3Service.presign(presignedS3RequestURL, bucket: nil, filename: "upload.\(mimeMappings[mimeType]!)", metadata: metadata, headers: headers, successHandler: { object in
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

    func createUser(withFacebookAccessToken token: FBSDKAccessToken, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        FBSDKGraphRequest(graphPath: token.userID, parameters: ["fields": "email,name"]).start { [weak self] connection, result, err in
            if let result = result as? [String: Any] {
                if let name = result["name"] as? String, let email = result["email"] as? String {
                    let params: [String: Any] = [
                        "name": name,
                        "email": email,
                        "password": UUID().uuidString,
                        "profile_image_url": "http://graph.facebook.com/\(token.userID)/picture?type=large",
                        "fb_user_id": token.userID,
                        "fb_access_token": token.tokenString,
                        "fb_access_token_expires_at": token.expirationDate.utcString,
                    ]
                    self?.createUser(params, onSuccess: onSuccess, onError: onError)
                } else {
                    onError(NSError(domain: "services.provide", code: -1, userInfo: nil), 500, "{}")
                }
            } else if let err = err {
                logWarn("FB graph API response failed; \(err)")
                onError(err as NSError, 500, "{}")
            }
        }
    }

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

    func fetchCurrentUser(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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
        let params: [String: Any] = [
            "public": true,
            "tags": ["profile_image", "default"],
        ]

        let data = UIImageJPEGRepresentation(image, 1.0)

        ApiService.shared.addAttachment(data!, withMimeType: "image/jpg", toUserWithId: String(currentUser.id), params: params, onSuccess: { response in
            onSuccess(response)

            ApiService.shared.fetchCurrentUser(onSuccess: { _, _ in
                if !UIApplication.shared.isRegisteredForRemoteNotifications {
                    KTNotificationCenter.post(name: .ProfileImageShouldRefresh)
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

    private func _deleteDeviceWithId(_ deviceId: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("devices/\(deviceId)", method: .DELETE, params: nil, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Remote notifications

    func registerForRemoteNotifications() {
        if !isSimulator() {
            KTNotificationCenter.post(name: .ApplicationWillRegisterUserNotificationSettings)

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

    func fetchCategories(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("categories", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: Provider API

    @discardableResult
    func fetchProviders(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> ApiOperation? {
        return dispatchApiOperationForPath("providers", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    func fetchProviderWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("providers/\(id)", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    private func _fetchProviderAvailability(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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

        params["heading"] = heading?.magneticHeading

        return checkin(params, onSuccess: { statusCode, mappingResult in
            logmoji("📌", "Checkin succeeded")
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

    // MARK: Work order API

    private func _fetchWorkOrderWithId(_ id: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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
        realParams["status"] = nil

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

    // MARK: Route API

    private func _fetchRoutes(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("routes", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func _fetchRouteWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("routes/\(id)", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    private func _updateRouteWithId(_ id: String, params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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
    func autocompletePlaces(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> ApiOperation? {
        return dispatchApiOperationForPath("directions/places", method: .GET, params: params, onSuccess: onSuccess, onError: onError)
    }

    // MARK: - Payment methods API

    private func _fetchPaymentMethods(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        dispatchApiOperationForPath("payment_methods", method: .GET, params: [:], onSuccess: onSuccess, onError: onError)
    }

    private func _createPaymentMethod(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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
    private func countTotalResultsForPath(_ path: String, params: [String: Any], onTotalResultsCount: @escaping OnTotalResultsCount) -> ApiOperation? {
        var params = params

        params["page"] = 1
        params["rpp"] = 0

        var op: ApiOperation?
        op = dispatchApiOperationForPath(path, method: .GET, params: params, startOperation: false, onSuccess: { statusCode, mappingResult in
            if let headers = op?.responseHeaders, let totalResultsCountString = headers["X-Total-Results-Count"] as? String, let totalResultsCount = Int(totalResultsCountString) {
                onTotalResultsCount(totalResultsCount, nil)
            }
        }, onError: { error, statusCode, responseString in
            onTotalResultsCount(-1, error as NSError?)
        })

        return op
    }

    @discardableResult
    private func dispatchApiOperationForPath(_ path: String, method: RKRequestMethod! = .GET, params: [String: Any]?, startOperation: Bool = true, onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> ApiOperation? {
        return dispatchOperationForURL(URL(string: CurrentEnvironment.baseUrlString)!, path: "api/\(path)", method: method, params: params, contentType: "application/json", startOperation: startOperation, onSuccess: onSuccess, onError: onError)
    }

    private func objectMappingForPath(_ path: String, method: String) -> RKObjectMapping? {
        var path = path
        let parts = path.split(separator: "/").map { String($0) }
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
    private func dispatchOperationForURL(_ baseURL: URL, path: String, method: RKRequestMethod = .GET, params: [String: Any]?, contentType: String = "application/json", startOperation: Bool = true, onSuccess: @escaping OnSuccess, onError: @escaping OnError) -> ApiOperation? {
        var responseMapping = objectMappingForPath(path, method: RKStringFromRequestMethod(method).lowercased())
        if responseMapping == nil {
            responseMapping = RKObjectMapping(for: nil)
        }

        if let descriptor = RKResponseDescriptor(mapping: responseMapping, method: method, pathPattern: nil, keyPath: nil, statusCodes: nil) {
            var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if [.GET, .HEAD].contains(method) && params?.isEmpty == false {
                urlComponents.query = params?.toQueryString()
            }

            let request = requestFactory(url: urlComponents.url!,
                                         httpMethod: RKStringFromRequestMethod(method),
                                         headers: nil,
                                         contentType: contentType,
                                         entity: params?.toJSONString().data(using: .utf8))

            let op = ApiOperation(session: urlSession!, request: request, responseDescriptor: descriptor, onSuccess: onSuccess, onError: onError)
            dispatchApiOperation(op)

            return op
        }

        return nil
    }

    private func dispatchApiOperation(_ operation: ApiOperation) {
        if operation.isCancelled {
            logWarn("Attempted to dispatch a canceled API operation: \(operation)")
        }
        opQueue.addOperation(operation)
    }

    @discardableResult
    private func requestFactory(url: URL, httpMethod: String, headers: [String: String]?, contentType: String?, entity: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "accept")

        for (name, value) in self.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        if let headers = headers {
            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        if ["PATCH", "POST", "PUT"].contains(httpMethod) {
            let _contentType = contentType ?? "application/json"
            request.setValue(_contentType, forHTTPHeaderField: "content-type")

            if let entity = entity, _contentType.lowercased() == "application/json" {
                request.httpBody = entity
            } else {
                logWarn("Request factory encountered unimplemented content-type: \(_contentType)")
            }
        }

        return request
    }
}

extension ApiService: URLSessionDelegate {

}

extension ApiService: URLSessionTaskDelegate {

}
