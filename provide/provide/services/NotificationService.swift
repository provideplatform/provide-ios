//
//  NotificationService.swift
//  provide
//
//  Created by Kyle Thomas on 11/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import JavaScriptCore
import jetfire
import KTSwiftExtensions

class NotificationService: NSObject, JFRWebSocketDelegate {
    static let shared = NotificationService()

    fileprivate let socketQueue = DispatchQueue(label: "api.websocketQueue", attributes: [])

    fileprivate var socket: JFRWebSocket!

    fileprivate var socketConnected: Bool {
        if let socket = socket {
            return socket.isConnected
        }
        return false
    }

    fileprivate var socketTimer: Timer!

    override init() {
        super.init()
    }

    func configureWebsocket() {
        disconnectWebsocket()

        socket = JFRWebSocket(url: URL(string: CurrentEnvironment.websocketBaseUrlString), protocols: [])
        socket.queue = socketQueue
        socket.delegate = self

        if let token = KeyChainService.shared.token {
            socket.addHeader(token.authorizationHeaderString, forKey: "X-API-Authorization")
        }
    }

    func connectWebsocket() {
        disconnectWebsocket()
        configureWebsocket()

        if let socket = socket {
            socket.connect()

            socketTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(maintainWebsocketConnection), userInfo: nil, repeats: true)
        }
    }

    func disconnectWebsocket() {
        if let socket = socket {
            socket.disconnect()

            self.socket = nil
        }

        socketTimer?.invalidate()
        socketTimer = nil
    }

    func maintainWebsocketConnection() {
        if socket != nil {
            if !socketConnected {
                connectWebsocket()
            }
        }
    }

    func dispatchRemoteNotification(_ userInfo: [String: AnyObject]) {
        let (notificationType, notificationValue) = PushNotificationType.typeAndValueFromUserInfo(userInfo)

        switch notificationType {
        case .attachment:
            if let refreshProfileImage = userInfo["refresh_profile_image"] as? Bool {
                if refreshProfileImage {
                    if let token = KeyChainService.shared.token {
                        if let user = token.user {
                            user.reload(
                                { statusCode, mappingResult in
                                    NotificationCenter.default.postNotificationName("ProfileImageShouldRefresh")
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }
                    }
                }
            }

            if !socketConnected {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "AttachmentChanged"), object: userInfo)
            }

        case .comment:
            let jsonString = (notificationValue as! [String: AnyObject]).toJSONString()
            let comment = Comment(string: jsonString)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "CommentChanged"), object: comment as Any)

        case .message:
            let jsonString = (notificationValue as! [String: AnyObject]).toJSONString()
            let message = Message(string: jsonString)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "NewMessageReceivedNotification"), object: message as Any)

        case .workOrder:
            if !socketConnected {
                let workOrderId = notificationValue as! Int
                if let workOrder = WorkOrderService.shared.workOrderWithId(workOrderId) {
                    workOrder.reload(
                        { statusCode, mappingResult in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "WorkOrderChanged"), object: workOrder)
                        },
                        onError: { error, statusCode, responseString in
                        }
                    )
                }

                if let providerRemoved = userInfo["provider_removed"] as? Bool {
                    if providerRemoved {
                        log("provider removed from work order id \(workOrderId)")
                    }
                } else {
                    if let inProgressWorkOrder = WorkOrderService.shared.inProgressWorkOrder {
                        if inProgressWorkOrder.id == workOrderId {
                            inProgressWorkOrder.reload(
                                { statusCode, mappingResult in
                                    WorkOrderService.shared.updateWorkOrder(inProgressWorkOrder)

                                    if inProgressWorkOrder.status == "canceled" {
                                        LocationService.shared.unregisterRegionMonitor(inProgressWorkOrder.regionIdentifier) // FIXME-- put this somewhere else, like in the workorder service
                                        NotificationCenter.default.postNotificationName("WorkOrderContextShouldRefresh")
                                    }

                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "WorkOrderChanged"), object: inProgressWorkOrder)
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }
                    } else {
                        NotificationCenter.default.postNotificationName("WorkOrderContextShouldRefresh")
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: JFRWebSocketDelegate

    @objc func websocketDidConnect(_ socket: JFRWebSocket) {
        AnalyticsService.shared.track("Websocket Connected", properties: [:])
    }

    @objc func websocketDidDisconnect(_ socket: JFRWebSocket, error: Error?) {
        AnalyticsService.shared.track("Websocket Disconnected", properties: [:])
        connectWebsocket()
    }

    @objc func websocket(_ socket: JFRWebSocket, didReceiveMessage message: String) {
        if let token = KeyChainService.shared.token {
            if message =~ ".*(client_connected).*" {
                socket.write("[\"websocket_rails.subscribe_private\",{\"data\":{\"channel\":\"user_\(token.user.id)\"}}]")
            } else if message =~ ".*(websocket_rails.ping).*" {
                socket.write("[\"websocket_rails.pong\",{\"data\":{}}]")
            } else if message =~ "^\\[\\[\"push\"" {
                let context = JSContext()
                if let value = context?.evaluateScript("eval('\(message)')[0][1]")?.toDictionary() {
                    if let data = value["data"] as? [String: AnyObject] {
                        let message = data["message"] as? String
                        let payload = data["payload"] as? [String: AnyObject]

                        if let message = message {
                            logInfo("Websocket message received: \(message)")

                            AnalyticsService.shared.track("Websocket Received Message",
                                                                   properties: ["message": message as AnyObject] as [String: AnyObject])

                            switch message {
                            case "attachment_changed":
                                let attachment = Attachment(string: payload!.toJSONString())
                                if let url = payload!["url"] as? String {
                                    attachment.urlString = url // FIXME-- marshall with proper mapping
                                }
                                if let attachableType = attachment.attachableType {
                                    if attachableType == "work_order" {
                                        if let workOrder = WorkOrderService.shared.workOrderWithId(attachment.attachableId) {
                                            workOrder.mergeAttachment(attachment)
                                        }
                                    }
                                }
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "AttachmentChanged"), object: attachment as Any)
                            case "comment_changed":
                                let comment = Comment(string: payload!.toJSONString())
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "CommentChanged"), object: comment as Any)
                            case "provider_became_available":
                                let providerJson = payload!.toJSONString()
                                let provider = Provider(string: providerJson)
                                if ProviderService.shared.containsProvider(provider) {
                                    ProviderService.shared.updateProvider(provider)
                                } else {
                                    ProviderService.shared.appendProvider(provider)
                                }
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "ProviderBecameAvailable"), object: provider as Any)
                            case "provider_became_unavailable":
                                if let providerId = payload?["provider_id"] as? Int {
                                    if let provider = ProviderService.shared.cachedProvider(providerId) {
                                        ProviderService.shared.removeProvider(providerId)
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: "ProviderBecameUnavailable"), object: provider as Any)
                                    }
                                }
                            case "provider_location_changed":
                                let providerJson = payload!.toJSONString()
                                let provider = Provider(string: providerJson)
                                if ProviderService.shared.containsProvider(provider) {
                                    ProviderService.shared.updateProvider(provider)
                                } else {
                                    ProviderService.shared.appendProvider(provider)
                                }
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "ProviderLocationChanged"), object: provider as Any)
                            case "work_order_changed":
                                let workOrderJson = payload!.toJSONString()
                                let workOrder = WorkOrder(string: workOrderJson)
                                WorkOrderService.shared.updateWorkOrder(workOrder)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "WorkOrderChanged"), object: workOrder as Any)
                                if WorkOrderService.shared.inProgressWorkOrder == nil {
                                    NotificationCenter.default.postNotificationName("WorkOrderContextShouldRefresh")
                                }
                            case "work_order_provider_changed":
                                let workOrderProviderJson = payload!.toJSONString()
                                let workOrderProvider = WorkOrderProvider(string: workOrderProviderJson)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "WorkOrderProviderChanged"), object: workOrderProvider as Any)
                                if WorkOrderService.shared.inProgressWorkOrder == nil {
                                    NotificationCenter.default.postNotificationName("WorkOrderContextShouldRefresh")
                                }
                            case "work_order_provider_added":
                                break
                            case "work_order_provider_removed":
                                break
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}
