//
//  AppDelegate.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import KTSwiftExtensions
import RestKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    fileprivate var launchScreenViewController: UIViewController!

    fileprivate var suppressLaunchScreenViewController = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if !isSimulator() {
            Fabric.with([Crashlytics()])
        }

        AnalyticsService.sharedService().track("App Launched", properties: ["Version": "\(KTVersionHelper.fullVersion())" as AnyObject] as [String: AnyObject])

        RKLogConfigureFromEnvironment()

        RKObjectMapping.setDefaultSourceToDestinationKeyTransformationBlock { objectMapping, keyPath in
            return keyPath?.snakeCaseToCamelCaseString()
        }

        AppearenceProxy.setup()

        if ApiService.sharedService().hasCachedToken {
            ApiService.sharedService().registerForRemoteNotifications()
            NotificationService.sharedService().connectWebsocket()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        renderLaunchScreenViewController()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsService.sharedService().track("App Entered Background", properties: [:])
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if ApiService.sharedService().hasCachedToken {
            NotificationCenter.default.postNotificationName("WorkOrderContextShouldRefresh")
        }

        dismissLaunchScreenViewController()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AnalyticsService.sharedService().track("App Became Active", properties: [:])

        if launchScreenViewController == nil {
            setupLaunchScreenViewController()
        } else {
            dismissLaunchScreenViewController()
        }

        if ApiService.sharedService().hasCachedToken {
            CheckinService.sharedService().checkin()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AnalyticsService.sharedService().track("App Will Terminate", properties: [:])
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        return openURL(url)
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return openURL(url)
    }

    fileprivate func openURL(_ url: URL) -> Bool {
        var handleScheme = false
        if let scheme = url.scheme?.lowercased() {
            handleScheme = scheme == "provide"
        }
        if handleScheme {
            var params: [String: AnyObject] = [:]
            if let queryComponent = url.query?.components(separatedBy: "params=").last?.removingPercentEncoding {
                params = queryComponent.toJSONObject()
            }
            let jwtToken = params["token"] as? String

            if !ApiService.sharedService().hasCachedToken {
                if let jwtToken = jwtToken {
                    if let jwt = KTJwtService.decode(jwtToken) {
                        if ApiService.sharedService().login(jwt) {
                            NotificationCenter.default.postNotificationName("ApplicationUserWasAuthenticated")
                            return self.openURL(url)
                        } else {
                            NotificationCenter.default.postNotificationName("ApplicationShouldShowInvalidCredentialsToast")
                        }
                    } else {
                        NotificationCenter.default.postNotificationName("ApplicationShouldShowInvalidCredentialsToast")
                    }
                }

                if url.host == "accept-invitation" {
                    NotificationCenter.default.postNotificationName("ApplicationShouldPresentPinInputViewController")
                }
            } else {
                if let jwtToken = jwtToken {
                    if let jwt = KTJwtService.decode(jwtToken) {
                        if let userId = jwt.body["user_id"] as? Int {
                            if userId != currentUser.id {
                                NotificationCenter.default.postNotificationName("ApplicationShouldShowInvalidCredentialsToast")
                            }
                        }
                    }
                }
            }
        }

        return false
    }

    // MARK: Remote notifications

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ApiService.sharedService().createDevice(["user_id": currentUser.id as AnyObject, "apns_device_id": "\(deviceToken)" as AnyObject],
            onSuccess: { statusCode, responseString in
                AnalyticsService.sharedService().track("App Registered For Remote Notifications")
            },
            onError: { error, statusCode, responseString in
                if statusCode == 409 {
                    AnalyticsService.sharedService().track("App Registered For Remote Notifications")
                } else {
                    logWarn("Failed to set apn device token for authenticated user; status code: \(statusCode)")
                }
            }
        )
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AnalyticsService.sharedService().track("App Failed To Register For Remote Notifications")

        log(error.localizedDescription)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AnalyticsService.sharedService().track("Remote notification received", properties: ["userInfo": userInfo as AnyObject, "received_at": "\(Date().timeIntervalSince1970)" as AnyObject] as [String: AnyObject])

        if ApiService.sharedService().hasCachedToken {
            NotificationService.sharedService().dispatchRemoteNotification(userInfo as! [String: AnyObject])
        }

        completionHandler(.newData)
    }

    // MARK: Privacy view controller

    fileprivate func setupLaunchScreenViewController() {
        launchScreenViewController = Bundle.main.loadNibNamed("LaunchScreen", owner: self, options: nil)?.first as! UIViewController

        let notificationNames = ["ApplicationWillRegisterUserNotificationSettings", "ApplicationWillRequestLocationAuthorization", "ApplicationWillRequestMediaAuthorization"]
        for notificationName in notificationNames {
            NotificationCenter.default.addObserverForName(notificationName) { _ in
                self.suppressLaunchScreenViewController = true
            }
        }

        NotificationCenter.default.addObserverForName(NSNotification.Name.UIApplicationDidChangeStatusBarOrientation.rawValue) { notification in
            DispatchQueue.main.async {
                self.launchScreenViewController.view.frame = self.window!.frame
            }
        }
    }

    fileprivate func renderLaunchScreenViewController() {
        if !suppressLaunchScreenViewController {
            window!.addSubview(launchScreenViewController.view)
            window!.bringSubview(toFront: launchScreenViewController.view)
        }

        suppressLaunchScreenViewController = false
    }

    fileprivate func dismissLaunchScreenViewController() {
        if launchScreenViewController?.view.superview != nil {
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn,
                animations: {
                    self.launchScreenViewController?.view.alpha = 0.0
                },
                completion: { complete in
                    self.launchScreenViewController?.view.removeFromSuperview()
                    self.launchScreenViewController?.view.alpha = 1.0
                }
            )
        }
    }
}
