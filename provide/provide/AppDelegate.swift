//
//  AppDelegate.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if !isSimulator() {
            Crashlytics.startWithAPIKey("0e160bf5b619e0ad44f93215d487d78bf8536287")
        }

        AnalyticsService.sharedService().track("App Launched", properties: ["Version": "\(VersionHelper.fullVersion())"])

        RKLogConfigureFromEnvironment()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Nothing
    }

    func applicationDidEnterBackground(application: UIApplication) {
        AnalyticsService.sharedService().track("App Entered Background", properties: [:])
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if ApiService.hasCachedToken() {
            NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        AnalyticsService.sharedService().track("App Became Active", properties: [:])

        if ApiService.hasCachedToken() {
            CheckinService.sharedService().checkin()
        }
    }

    // MARK: Remote notifications

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        ApiService.sharedService().createDevice(["user_id": currentUser().id, "apns_device_id": "\(deviceToken)"],
            onSuccess: { statusCode, responseString in
                AnalyticsService.sharedService().track("App Registered For Remote Notifications")
            },
            onError: { error, statusCode, responseString in
                logError("Failed to set apn device token for authenticated user")
            }
        )
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        AnalyticsService.sharedService().track("App Failed To Register For Remote Notifications")

        log(error.localizedDescription)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        AnalyticsService.sharedService().track("Remote notification received", properties: ["userInfo": userInfo, "received_at": "\(NSDate().timeIntervalSince1970)"])

        if ApiService.hasCachedToken() {
            handleRemoteNotification(userInfo as! [String: AnyObject])
        }

        completionHandler(.NewData)
    }

    func handleRemoteNotification(userInfo: [String: AnyObject]) {
        let (notificationType, notificationValue) = PushNotificationType.typeAndValueFromUserInfo(userInfo)

        switch notificationType {
        case .CheckIn:
            let checkin = notificationValue as! Bool
            if checkin {
                LocationService.sharedService().resolveCurrentLocation { location in
                    ApiService.sharedService().checkin(location)
                    LocationService.sharedService().background()
                }
            }
        case .Message:
            let message = Message(string: (notificationValue as! NSDictionary).toJSON())
            NSNotificationCenter.defaultCenter().postNotificationName("NewMessageReceivedNotification", object: message)
        case .WorkOrder:
            let workOrderId = notificationValue as! NSNumber
            if let providerRemoved = userInfo["provider_removed"] as? Bool {
                if providerRemoved {
                    log("provider removed from work order id \(workOrderId)")
                }
            } else {
                if WorkOrderService.sharedService().inProgressWorkOrder != nil {
                    if WorkOrderService.sharedService().inProgressWorkOrder.id == workOrderId.integerValue {
                        ApiService.sharedService().fetchWorkOrderWithId(workOrderId.stringValue,
                            onSuccess: { statusCode, mappingResult in
                                if let wo = mappingResult.firstObject as? WorkOrder {
                                    if wo.status == "canceled" {
                                        LocationService.sharedService().unregisterRegionMonitor(wo.regionIdentifier) // FIXME-- put this somewhere else, like in the workorder service
                                        NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                                    }
                                }
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
    }

    func applicationWillTerminate(application: UIApplication) {
        AnalyticsService.sharedService().track("App Will Terminate", properties: [:])
    }
}
