//
//  NotificationService.swift
//  provide
//
//  Created by Kyle Thomas on 11/16/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import JavaScriptCore
import jetfire
import KTSwiftExtensions

class NotificationService: NSObject, JFRWebSocketDelegate {

    private static let sharedInstance = NotificationService()

    private let socketQueue = dispatch_queue_create("api.websocketQueue", nil)

    private var socket: JFRWebSocket!

    private var socketConnected: Bool {
        if let socket = socket {
            return socket.isConnected
        }
        return false
    }

    private var socketTimer: NSTimer!

    class func sharedService() -> NotificationService {
        return sharedInstance
    }

    override init() {
        super.init()
    }

    func configureWebsocket() {
        disconnectWebsocket()

        socket = JFRWebSocket(URL: NSURL(CurrentEnvironment.websocketBaseUrlString), protocols: [])
        socket.queue = socketQueue
        socket.delegate = self

        if let token = KeyChainService.sharedService().token {
            socket.addHeader(token.authorizationHeaderString, forKey: "X-API-Authorization")
        }
    }

    func connectWebsocket() {
        disconnectWebsocket()
        configureWebsocket()

        if let socket = socket {
            socket.connect()

            socketTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: #selector(NotificationService.maintainWebsocketConnection), userInfo: nil, repeats: true)
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
        if let _ = socket {
            if !socketConnected {
                connectWebsocket()
            }
        }
    }

    func dispatchRemoteNotification(userInfo: [String: AnyObject]) {
        let (notificationType, notificationValue) = PushNotificationType.typeAndValueFromUserInfo(userInfo)

        switch notificationType {
        case .Attachment:
            if let refreshProfileImage = userInfo["refresh_profile_image"] as? Bool {
                if refreshProfileImage {
                    if let token = KeyChainService.sharedService().token {
                        if let user = token.user {
                            user.reload(
                                { statusCode, mappingResult in
                                    NSNotificationCenter.defaultCenter().postNotificationName("ProfileImageShouldRefresh")
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }
                    }
                }
            }

            if !socketConnected {
                NSNotificationCenter.defaultCenter().postNotificationName("AttachmentChanged", object: userInfo)
            }
        case .Comment:
            let jsonString = (notificationValue as! [String: AnyObject]).toJSONString()
            let comment = Comment(string: jsonString)
            NSNotificationCenter.defaultCenter().postNotificationName("CommentChanged", object: comment)
        case .Job:
            if !socketConnected {
                let jobId = notificationValue as! Int
                if let job = JobService.sharedService().jobWithId(jobId) {
                    job.reload(
                        onSuccess: { statusCode, mappingResult in
                            NSNotificationCenter.defaultCenter().postNotificationName("JobChanged", object: job)
                        },
                        onError: { error, statusCode, responseString in
                        }
                    )
                }
                if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                    if inProgressWorkOrder.jobId == jobId {
                        log("received update for current job id \(jobId)")
                    } else {
                        NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                    }
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                }
            }
        case .Message:
            let jsonString = (notificationValue as! [String: AnyObject]).toJSONString()
            let message = Message(string: jsonString)
            NSNotificationCenter.defaultCenter().postNotificationName("NewMessageReceivedNotification", object: message)
        case .Route:
            let routeId = notificationValue as! NSNumber
            if let currentRoute = RouteService.sharedService().currentRoute {
                if currentRoute.id == routeId {
                    log("received update for current route id \(routeId)")
                }
            } else {
                if let nextRoute = RouteService.sharedService().nextRoute {
                    if nextRoute.id == routeId {
                        log("received update for next route id \(routeId)")
                    }
                }
                NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
            }
        case .WorkOrder:
            if !socketConnected {
                let workOrderId = notificationValue as! Int
                if let workOrder = WorkOrderService.sharedService().workOrderWithId(workOrderId) {
                    workOrder.reload(
                        onSuccess: { statusCode, mappingResult in
                            NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderChanged", object: workOrder)
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
                    if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                        if inProgressWorkOrder.id == workOrderId {
                            inProgressWorkOrder.reload(onSuccess: { statusCode, mappingResult in
                                WorkOrderService.sharedService().updateWorkOrder(inProgressWorkOrder)

                                if inProgressWorkOrder.status == "canceled" {
                                    LocationService.sharedService().unregisterRegionMonitor(inProgressWorkOrder.regionIdentifier) // FIXME-- put this somewhere else, like in the workorder service
                                    NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                                }

                                NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderChanged", object: inProgressWorkOrder)
                                },
                                                       onError: { error, statusCode, responseString in

                                }
                            )
                        }
                    } else {
                        NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: JFRWebSocketDelegate

    @objc func websocketDidConnect(socket: JFRWebSocket) {
        AnalyticsService.sharedService().track("Websocket Connected", properties: [:])
    }

    @objc func websocketDidDisconnect(socket: JFRWebSocket, error: NSError?) {
        AnalyticsService.sharedService().track("Websocket Disconnected", properties: [:])
        connectWebsocket()
    }

    @objc func websocket(socket: JFRWebSocket, didReceiveMessage message: String) {
        if let token = KeyChainService.sharedService().token {
            if message =~ ".*(client_connected).*" {
                socket.writeString("[\"websocket_rails.subscribe_private\",{\"data\":{\"channel\":\"user_\(token.user.id)\"}}]")
            } else if message =~ ".*(websocket_rails.ping).*" {
                socket.writeString("[\"websocket_rails.pong\",{\"data\":{}}]")
            } else if message =~ "^\\[\\[\"push\"" {
                let context = JSContext()
                if let value = context.evaluateScript("eval('\(message)')[0][1]")?.toDictionary() {
                    if let data = value["data"] as? [String : AnyObject] {
                        let message = data["message"] as? String
                        let payload = data["payload"] as? [String : AnyObject]

                        if let message = message {
                            AnalyticsService.sharedService().track("Websocket Received Message", properties: ["message": message])

                            switch message {
                            case "attachment_changed":
                                let attachment = Attachment(string: payload!.toJSONString())
                                if let url = payload!["url"] as? String {
                                    attachment.urlString = url // FIXME-- marshall with proper mapping
                                }
                                if let attachableType = attachment.attachableType {
                                    if attachableType == "job" {
                                        if let job = JobService.sharedService().jobWithId(attachment.attachableId) {
                                            job.mergeAttachment(attachment)
                                        }
                                    } else if attachableType == "work_order" {
                                        if let workOrder = WorkOrderService.sharedService().workOrderWithId(attachment.attachableId) {
                                            workOrder.mergeAttachment(attachment)
                                        }
                                    }
                                }
                                NSNotificationCenter.defaultCenter().postNotificationName("AttachmentChanged", object: attachment)
                                break

                            case "comment_changed":
                                let comment = Comment(string: payload!.toJSONString())
                                NSNotificationCenter.defaultCenter().postNotificationName("CommentChanged", object: comment)

                            case "floorplan_changed":
                                let floorplan = Floorplan(string: payload!.toJSONString())
                                FloorplanService.sharedService().updateFloorplan(floorplan)
                                NSNotificationCenter.defaultCenter().postNotificationName("FloorplanChanged", object: floorplan)
                                break

                            case "job_changed":
                                let job = Job(string: payload!.toJSONString())
                                JobService.sharedService().updateJob(job)
                                NSNotificationCenter.defaultCenter().postNotificationName("JobChanged", object: job)
                                break

                            case "work_order_changed":
                                let workOrderJson = payload!.toJSONString()
                                let workOrder = WorkOrder(string: workOrderJson)
                                var annotations = [Annotation]()
                                if let workOrderAnnotations = workOrderJson.toJSONObject()["annotations"] as? NSArray { // HACK
                                    for workOrderAnnotation in workOrderAnnotations.objectEnumerator().allObjects {
                                        annotations.append(Annotation(string: (workOrderAnnotation as! NSDictionary).toJSON()))
                                    }
                                }
                                workOrder.annotations = annotations
                                WorkOrderService.sharedService().updateWorkOrder(workOrder)
                                NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderChanged", object: workOrder)
                                if WorkOrderService.sharedService().inProgressWorkOrder == nil {
                                    NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                                }
                                break

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
