//
//  NSNotification.Name.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/14/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let ApplicationShouldPresentPinInputViewController = NSNotification.Name("ApplicationShouldPresentPinInputViewController")
    static let ApplicationShouldReloadTopViewController = NSNotification.Name("ApplicationShouldReloadTopViewController")
    static let ApplicationShouldShowInvalidCredentialsToast = NSNotification.Name("ApplicationShouldShowInvalidCredentialsToast")
    static let ApplicationWillResignActive = NSNotification.Name("ApplicationWillResignActive")
    static let ApplicationUserLoggedOut = NSNotification.Name("ApplicationUserLoggedOut")
    static let ApplicationUserShouldLogout = NSNotification.Name("ApplicationUserShouldLogout")
    static let ApplicationUserWasAuthenticated = NSNotification.Name("ApplicationUserWasAuthenticated")
    static let ApplicationShouldForceLogout = NSNotification.Name("ApplicationShouldForceLogout")
    static let ApplicationWillRegisterUserNotificationSettings = NSNotification.Name("ApplicationWillRegisterUserNotificationSettings")
    static let ApplicationWillRequestLocationAuthorization = NSNotification.Name("ApplicationWillRequestLocationAuthorization")
    static let ApplicationWillRequestMediaAuthorization = NSNotification.Name("ApplicationWillRequestMediaAuthorization")
    static let AttachmentChanged = Notification.Name("AttachmentChanged")
    static let CategorySelectionChanged = NSNotification.Name("CategorySelectionChanged")
    static let MenuContainerShouldOpen = NSNotification.Name("MenuContainerShouldOpen")
    static let MenuContainerShouldReset = NSNotification.Name("MenuContainerShouldReset")
    static let MessagesViewControllerPoppedNotification = Notification.Name("MessagesViewControllerPoppedNotification")
    static let NewMessageReceivedNotification = Notification.Name("NewMessageReceivedNotification")
    static let PaymentMethodShouldBeRemoved = NSNotification.Name("PaymentMethodShouldBeRemoved")
    static let ProfileImageShouldRefresh = NSNotification.Name("ProfileImageShouldRefresh")
    static let ProviderBecameAvailable = Notification.Name("ProviderBecameAvailable")
    static let ProviderBecameUnavailable = Notification.Name("ProviderBecameUnavailable")
    static let ProviderLocationChanged = Notification.Name("ProviderLocationChanged")
    static let WorkOrderChanged = Notification.Name("WorkOrderChanged")
    static let WorkOrderContextShouldRefresh = NSNotification.Name("WorkOrderContextShouldRefresh")
    static let WorkOrderStatusChanged = NSNotification.Name("WorkOrderStatusChanged")
    static let WorkOrderOverviewShouldRender = NSNotification.Name("WorkOrderOverviewShouldRender")
}
