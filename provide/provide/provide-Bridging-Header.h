//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

// CocoaPods
//#import <Analytics/SEGAnalytics.h>
#import <CardIO/CardIO.h>
#import <ELFixSecureTextFieldFont/UITextField+ELFixSecureTextFieldFont.h>
#import <jetfire/JFRWebSocket.h>
#import <JSQMessagesViewController/JSQMessages.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <PDTSimpleCalendar/PDTSimpleCalendar.h>
#import <SWTableViewCell/SWTableViewCell.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

// SDWebImage Workaround
#undef __IPHONE_OS_VERSION_MIN_REQUIRED
#define __IPHONE_OS_VERSION_MIN_REQUIRED __IPHONE_7_0
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImageView+HighlightedWebCache.h>


@import BadgeSwift;
@import FirebaseAnalytics;
@import FontAwesomeKit;
@import KTSwiftExtensions;
@import LinkKit;
@import RestKit;
