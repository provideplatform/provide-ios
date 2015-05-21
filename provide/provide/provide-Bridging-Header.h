//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <UIKit/UIGestureRecognizerSubclass.h>

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

// CocoaPods
#import <Analytics/Analytics.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <ECSlidingViewController/ECSlidingSegue.h>
#import <ECSlidingViewController/ECSlidingViewController.h>
#import <ELFixSecureTextFieldFont/UITextField+ELFixSecureTextFieldFont.h>
#import <MKNetworkKit/MKNetworkKit.h>
#import <RestKit/RestKit.h>
#import <RFGravatarImageView/RFGravatarImageView.h>
#import <SevenSwitch/SevenSwitch.h>
#import <SWTableViewCell/SWTableViewCell.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "UIViewController+ECSlidingViewController.h"

// SDWebImage Workaround
#undef __IPHONE_OS_VERSION_MIN_REQUIRED
#define __IPHONE_OS_VERSION_MIN_REQUIRED __IPHONE_7_0
#import <SDWebImage/UIImageView+WebCache.h>

// provideKIFTests
#ifdef KIF_TESTS
#import <KIF/KIF.h>
#endif
