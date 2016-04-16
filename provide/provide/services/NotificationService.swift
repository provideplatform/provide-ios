//
//  NotificationService.swift
//  provide
//
//  Created by Kyle Thomas on 11/16/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class NotificationService: NSObject {

    private static let sharedInstance = NotificationService()

    class func sharedService() -> NotificationService {
        return sharedInstance
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

            NSNotificationCenter.defaultCenter().postNotificationName("AttachmentChanged", object: userInfo)
        case .Checkin:
            let checkin = notificationValue as! Bool
            if checkin {
                LocationService.sharedService().resolveCurrentLocation { location in
                    ApiService.sharedService().checkin(location)
                    LocationService.sharedService().background()
                }
            }
        case .Job:
            let jobId = notificationValue as! Int
            if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                if inProgressWorkOrder.jobId == jobId {
                    log("received update for current job id \(jobId)")
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                }
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
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
        default:
            break
        }
    }
}
