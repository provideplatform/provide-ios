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

    private let socketQueue = DispatchQueue(label: "api.websocketQueue", attributes: [])

    private var socket: JFRWebSocket!

    private var socketConnected: Bool {
        return socket?.isConnected ?? false
    }

    private var socketTimer: Timer!

    private func configureWebsocket() {
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

    @objc func maintainWebsocketConnection() {
        if socket != nil {
            if !socketConnected {
                connectWebsocket()
            }
        }
    }

    func dispatchRemoteNotification(_ userInfo: [String: Any]) {
        // logmoji("📣", "dispatchRemoteNotification: \(userInfo)")
        let (notificationType, notificationValue) = PushNotificationType.typeAndValueFromUserInfo(userInfo)

        switch notificationType {
        case .attachment:
            if let refreshProfileImage = userInfo["refresh_profile_image"] as? Bool, KeyChainService.shared.token?.user != nil && refreshProfileImage {
                ApiService.shared.fetchCurrentUser(onSuccess: { _, _ in
                    KTNotificationCenter.post(name: .ProfileImageShouldRefresh)
                }, onError: { error, statusCode, responseString in
                    logError(error)
                })
            }

            if !socketConnected {
                KTNotificationCenter.post(name: .AttachmentChanged, object: userInfo)
            }
        case .message:
            let jsonString = (notificationValue as! [String: Any]).toJSONString()
            let message = Message(string: jsonString)
            KTNotificationCenter.post(name: .NewMessageReceivedNotification, object: message)

        case .workOrder:
            if !socketConnected {
                let workOrderId = notificationValue as! Int
                if let workOrder = WorkOrderService.shared.workOrderWithId(workOrderId) {
                    workOrder.reload(onSuccess: { statusCode, mappingResult in
                        KTNotificationCenter.post(name: .WorkOrderChanged, object: workOrder)
                    }, onError: { error, statusCode, responseString in
                        logError(error)
                    })
                }

                if let providerRemoved = userInfo["provider_removed"] as? Bool, providerRemoved {
                    log("provider removed from work order id \(workOrderId)")
                } else {
                    if let inProgressWorkOrder = WorkOrderService.shared.inProgressWorkOrder {
                        if inProgressWorkOrder.id == workOrderId {
                            inProgressWorkOrder.reload(onSuccess: { statusCode, mappingResult in
                                WorkOrderService.shared.updateWorkOrder(inProgressWorkOrder)

                                if inProgressWorkOrder.status == "canceled" {
                                    LocationService.shared.unregisterRegionMonitor(inProgressWorkOrder.regionIdentifier) // FIXME-- put this somewhere else, like in the workorder service
                                    KTNotificationCenter.post(name: .WorkOrderContextShouldRefresh)
                                }

                                KTNotificationCenter.post(name: .WorkOrderChanged, object: inProgressWorkOrder)
                            }, onError: { error, statusCode, responseString in
                                logError(error)
                            })
                        }
                    } else {
                        KTNotificationCenter.post(name: .WorkOrderContextShouldRefresh)
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: JFRWebSocketDelegate

    @objc func websocketDidConnect(_ socket: JFRWebSocket) {
        AnalyticsService.shared.track("Websocket Connected")
    }

    @objc func websocketDidDisconnect(_ socket: JFRWebSocket, error: Error?) {
        AnalyticsService.shared.track("Websocket Disconnected")
        connectWebsocket()
    }

    private func pongMessage() -> String {
        return """
        ["websocket_rails.pong",{"data":{}}]
        """
    }

    private func subscribeMessage(forUser user: User) -> String {
        return """
        ["websocket_rails.subscribe_private",{"data":{"channel":"user_\(user.id)"}}]
        """
    }

    @objc func websocket(_ socket: JFRWebSocket, didReceiveMessage websocketMessage: String) {
        if !(websocketMessage =~ ".*websocket_rails.ping.*") {
            // logmoji("🔔", "websocket:didReceiveMessage: \(prettyPrintedJson(message))")
        }

        if let token = KeyChainService.shared.token {
            if websocketMessage =~ ".*(client_connected).*" {
                socket.write(subscribeMessage(forUser: token.user))
            } else if websocketMessage =~ ".*(websocket_rails.ping).*" {
                socket.write(pongMessage())
            } else if websocketMessage =~ "^\\[\\[\"push\"" {
                let context = JSContext()
                if let value = context?.evaluateScript("eval('\(websocketMessage)')[0][1]")?.toDictionary(),
                    let data = value["data"] as? [String: Any],
                    let messageName = data["message"] as? String,
                    let payload = data["payload"] as? [String: Any] {

                    logmoji("✴️", messageName)

                    if ProcessInfo.processInfo.environment["WRITE_JSON_RESPONSES"] != nil {
                        JSONResponseWriter.writeWebsocketMessageToFile(messageName, websocketMessage)
                    }

                    AnalyticsService.shared.track("Websocket Received Message", properties: ["message": messageName])

                    NotificationService.handleWebsocketMessage(messageName, payload: payload)
                }
            }
        }
    }

    static func handleWebsocketMessage(_ messageName: String, payload: [String: Any]) {
        switch messageName {
        case "attachment_changed":
            let attachment = Attachment(string: payload.toJSONString())
            if let url = payload["url"] as? String {
                attachment.urlString = url // FIXME-- marshall with proper mapping
            }

            if let attachableType = attachment.attachableType, attachableType == "work_order", let workOrder = WorkOrderService.shared.workOrderWithId(attachment.attachableId) {
                workOrder.mergeAttachment(attachment)
            }
            KTNotificationCenter.post(name: .AttachmentChanged, object: attachment)
        case "provider_became_available":
            let providerJson = payload.toJSONString()
            let provider = Provider(string: providerJson)
            if ProviderService.shared.containsProvider(provider) {
                ProviderService.shared.updateProvider(provider)
            } else {
                ProviderService.shared.appendProvider(provider)
            }
            KTNotificationCenter.post(name: .ProviderBecameAvailable, object: provider)
        case "provider_became_unavailable":
            if let providerId = payload["provider_id"] as? Int, let provider = ProviderService.shared.cachedProvider(providerId) {
                ProviderService.shared.removeProvider(providerId)
                KTNotificationCenter.post(name: .ProviderBecameUnavailable, object: provider)
            }
        case "provider_location_changed":
            let providerJson = payload.toJSONString()
            let provider = Provider(string: providerJson)
            if ProviderService.shared.containsProvider(provider) {
                ProviderService.shared.updateProvider(provider)
            } else {
                ProviderService.shared.appendProvider(provider)
            }
            KTNotificationCenter.post(name: .ProviderLocationChanged, object: provider)
        case "work_order_changed":
            let workOrderJson = payload.toJSONString()
            let workOrder = WorkOrder(string: workOrderJson)
            WorkOrderService.shared.updateWorkOrder(workOrder)
            KTNotificationCenter.post(name: .WorkOrderChanged, object: workOrder)
            if WorkOrderService.shared.inProgressWorkOrder == nil {
                KTNotificationCenter.post(name: .WorkOrderContextShouldRefresh, object: workOrder)
            }
            logmoji("⚛️", "status: \(workOrder.status)")
        case "work_order_provider_changed":
            if WorkOrderService.shared.inProgressWorkOrder == nil {
                KTNotificationCenter.post(name: .WorkOrderContextShouldRefresh)
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
