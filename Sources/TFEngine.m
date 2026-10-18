#import "TFEngine.h"
#import "TFPrefs.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

@implementation TFEngine

+ (instancetype)shared {
    static TFEngine *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [TFEngine new]; });
    return s;
}

- (void)telegramDidBecomeActive {
    TFPrefs *p = TFPrefs.shared;
    if (!p.enabled) return;
    if (p.freezeOtherApps) [self suspendOtherUserApps];
    if (p.aggressiveMemory) [self trimMemoryIfNeeded];
}

- (void)telegramDidResignActive {
}

- (void)suspendOtherUserApps {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.telefocus.tweak/suspendOthers"),
        NULL, NULL, true);
}

- (void)trimMemoryIfNeeded {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

@end
