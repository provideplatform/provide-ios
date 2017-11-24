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

        ReachabilityService.shared.start()

        if let jsonBaseDir = ProcessInfo.processInfo.environment["SERVE_JSON_RESPONSES"] {
            OHHTTPStubsHelper.serveJsonResponses(fromDir: jsonBaseDir)
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        KTNotificationCenter.post(name: .ApplicationWillResignActive)
        renderLaunchScreenViewController()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsService.shared.track("App Entered Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if ApiService.shared.hasCachedToken {
            KTNotificationCenter.post(name: .WorkOrderContextShouldRefresh)
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
                            KTNotificationCenter.post(name: .ApplicationUserWasAuthenticated)
                            return openURL(url)
                        } else {
                            KTNotificationCenter.post(name: .ApplicationShouldShowInvalidCredentialsToast)
                        }
                    } else {
                        KTNotificationCenter.post(name: .ApplicationShouldShowInvalidCredentialsToast)
                    }
                }

                if url.host == "accept-invitation" {
                    KTNotificationCenter.post(name: .ApplicationShouldPresentPinInputViewController)
                }
            } else {
                if let jwtToken = jwtToken, let jwt = KTJwtService.decode(jwtToken), let userId = jwt.body["user_id"] as? Int, userId != currentUser.id {
                    KTNotificationCenter.post(name: .ApplicationShouldShowInvalidCredentialsToast)
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
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        ApiService.shared.createDevice(["user_id": currentUser.id, "apns_device_id": token], onSuccess: { statusCode, responseString in
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

        let notificationNames: [NSNotification.Name] = [.ApplicationWillRegisterUserNotificationSettings, .ApplicationWillRequestLocationAuthorization, .ApplicationWillRequestMediaAuthorization]
        for notificationName in notificationNames {
            KTNotificationCenter.addObserver(forName: notificationName) { _ in
                self.suppressLaunchScreenViewController = true
            }
        }

        KTNotificationCenter.addObserver(forName: .UIApplicationDidChangeStatusBarOrientation, queue: .main) { notification in
            self.launchScreenViewController.view.frame = self.window!.frame
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
