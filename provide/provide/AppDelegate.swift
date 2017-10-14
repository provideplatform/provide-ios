//
//  AppDelegate.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var launchScreenViewController: UIViewController!

    private var suppressLaunchScreenViewController = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AnalyticsService.shared.track("App Launched", properties: ["Version": "\(KTVersionHelper.fullVersion())"])

        FirebaseApp.configure()

        RKLogConfigureFromEnvironment()

        RKObjectMapping.setDefaultSourceToDestinationKeyTransformationBlock { objectMapping, keyPath in
            return keyPath?.snakeCaseToCamelCaseString()
        }

        AppearenceProxy.setup()

        if ApiService.shared.hasCachedToken {
            ApiService.shared.registerForRemoteNotifications()
            NotificationService.shared.connectWebsocket()
        }

        if let jsonBaseDir = ProcessInfo.processInfo.environment["SERVE_JSON_RESPONSES"] {
            OHHTTPStubsHelper.serveJsonResponses(fromDir: jsonBaseDir)
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        renderLaunchScreenViewController()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsService.shared.track("App Entered Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if ApiService.shared.hasCachedToken {
            NotificationCenter.post(name: .WorkOrderContextShouldRefresh)
        }

        dismissLaunchScreenViewController()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AnalyticsService.shared.track("App Became Active")

        if launchScreenViewController == nil {
            setupLaunchScreenViewController()
        } else {
            dismissLaunchScreenViewController()
        }

        if ApiService.shared.hasCachedToken {
            CheckinService.shared.checkin()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AnalyticsService.shared.track("App Will Terminate")
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        return openURL(url)
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return openURL(url)
    }

    private func openURL(_ url: URL) -> Bool {
        var handleScheme = false
        if let scheme = url.scheme?.lowercased() {
            handleScheme = scheme == "provide"
        }
        if handleScheme {
            var params: [String: Any] = [:]
            if let queryComponent = url.query?.components(separatedBy: "params=").last?.removingPercentEncoding {
                params = queryComponent.toJSONObject()!
            }
            let jwtToken = params["token"] as? String

            if !ApiService.shared.hasCachedToken {
                if let jwtToken = jwtToken {
                    if let jwt = KTJwtService.decode(jwtToken) {
                        if ApiService.shared.login(jwt) {
                            NotificationCenter.default.postNotificationName("ApplicationUserWasAuthenticated")
                            return openURL(url)
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
                if let jwtToken = jwtToken, let jwt = KTJwtService.decode(jwtToken), let userId = jwt.body["user_id"] as? Int, userId != currentUser.id {
                    NotificationCenter.default.postNotificationName("ApplicationShouldShowInvalidCredentialsToast")
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
        ApiService.shared.createDevice(["user_id": currentUser.id, "apns_device_id": "\(deviceToken)"], onSuccess: { statusCode, responseString in
            AnalyticsService.shared.track("App Registered For Remote Notifications")
        }, onError: { error, statusCode, responseString in
            if statusCode == 409 {
                AnalyticsService.shared.track("App Registered For Remote Notifications")
            } else {
                logWarn("Failed to set apn device token for authenticated user; status code: \(statusCode)")
            }
        })
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AnalyticsService.shared.track("App Failed To Register For Remote Notifications")

        log(error.localizedDescription)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AnalyticsService.shared.track("Remote notification received", properties: ["userInfo": userInfo, "received_at": "\(Date().timeIntervalSince1970)"])

        if ApiService.shared.hasCachedToken {
            NotificationService.shared.dispatchRemoteNotification(userInfo as! [String: Any])
        }

        completionHandler(.newData)
    }

    // MARK: Privacy view controller

    private func setupLaunchScreenViewController() {
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

    private func renderLaunchScreenViewController() {
        if !suppressLaunchScreenViewController {
            window!.addSubview(launchScreenViewController.view)
            window!.bringSubview(toFront: launchScreenViewController.view)
        }

        suppressLaunchScreenViewController = false
    }

    private func dismissLaunchScreenViewController() {
        if launchScreenViewController?.view.superview != nil {
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
                self.launchScreenViewController?.view.alpha = 0.0
            }, completion: { complete in
                self.launchScreenViewController?.view.removeFromSuperview()
                self.launchScreenViewController?.view.alpha = 1.0
            })
        }
    }
}
