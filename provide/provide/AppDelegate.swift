//
//  AppDelegate.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        AnalyticsService.sharedService().track("App Launched", properties: ["Version": "\(VersionHelper.fullVersion())"])

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        AnalyticsService.sharedService().track("App Entered Background", properties: [:])
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        if ApiService.hasCachedToken() {
            NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

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
        ApiService.sharedService().createDevice(["user_id": KeyChainService.sharedService().token!.userId, "apns_device_id": "\(deviceToken)"],
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

        println(error.localizedDescription)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        AnalyticsService.sharedService().track("Remote notification received", properties: ["userInfo": userInfo, "received_at": "\(NSDate().timeIntervalSince1970)"])

        if ApiService.hasCachedToken() {
            if let checkin = userInfo["checkin"] as? Bool {
                if checkin {
                    LocationService.sharedService().resolveCurrentLocation { location in
                        ApiService.sharedService().checkin(location)
                        LocationService.sharedService().background()
                    }
                }
            }

            if let workOrderId = userInfo["work_order_id"] as? NSNumber {
                if let providerRemoved = userInfo["provider_removed"] as? Bool {
                    if providerRemoved == true {
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

        completionHandler(.NewData);
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        saveContext()

        AnalyticsService.sharedService().track("App Will Terminate", properties: [:])
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "services.provide" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("provide", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("provide.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

