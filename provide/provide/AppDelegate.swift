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

    private var launchScreenViewController: UIViewController!

    private var suppressLaunchScreenViewController = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if !isSimulator() {
            Fabric.with([Crashlytics()])
        }

        AnalyticsService.sharedService().track("App Launched", properties: ["Version": "\(VersionHelper.fullVersion())"])

        setupLaunchScreenViewController()

        RKLogConfigureFromEnvironment()

        RKEntityMapping.setDefaultSourceToDestinationKeyTransformationBlock { objectMapping, keyPath in
            return keyPath.snakeCaseToCamelCaseString()
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        renderLaunchScreenViewController()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        AnalyticsService.sharedService().track("App Entered Background", properties: [:])
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if ApiService.hasCachedToken() {
            NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
        }

        dismissLaunchScreenViewController()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        AnalyticsService.sharedService().track("App Became Active", properties: [:])

        dismissLaunchScreenViewController()

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
                logWarn("Failed to set apn device token for authenticated user")
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
            NotificationService.sharedService().dispatchRemoteNotification(userInfo as! [String : AnyObject])
        }

        completionHandler(.NewData)
    }

    func applicationWillTerminate(application: UIApplication) {
        AnalyticsService.sharedService().track("App Will Terminate", properties: [:])
    }

    private func setupLaunchScreenViewController() {
        launchScreenViewController = NSBundle.mainBundle().loadNibNamed("LaunchScreen", owner: self, options: nil).first as! UIViewController

        let notificationNames = ["ApplicationWillRegisterUserNotificationSettings", "ApplicationWillRequestLocationAuthorization", "ApplicationWillRequestMediaAuthorization"]
        for notificationName in notificationNames {
            NSNotificationCenter.defaultCenter().addObserverForName(notificationName) { _ in
                self.suppressLaunchScreenViewController = true
            }
        }
    }

    private func renderLaunchScreenViewController() {
        if !suppressLaunchScreenViewController {
            window!.addSubview(launchScreenViewController.view)
            window!.bringSubviewToFront(launchScreenViewController.view)
        }

        suppressLaunchScreenViewController = false
    }

    private func dismissLaunchScreenViewController() {
        if let _ = launchScreenViewController.view.superview {
            UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveEaseIn,
                animations: {
                    self.launchScreenViewController.view.alpha = 0.0
                },
                completion: { complete in
                    self.launchScreenViewController.view.removeFromSuperview()
                    self.launchScreenViewController.view.alpha = 1.0
                }
            )
        }
    }
}
