#import "TFEngine.h"
#import "TFPrefs.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/*
 * Freeze other user apps while Telegram is foreground.
 * We only target third-party bundle ids — never SpringBoard, backboardd, or system daemons.
 * Method: ask SpringBoard to suspend apps via public-ish notification + best-effort
 * UIApplication background task limits. Hard "kill all" is dangerous; we suspend.
 */

static BOOL TFIsSystemBundle(NSString *bid) {
    if (!bid.length) return YES;
    if ([bid hasPrefix:@"com.apple."]) return YES;
    if ([bid isEqualToString:@"ph.telegra.Telegraph"]) return YES;
    // Common system-ish
    if ([bid hasPrefix:@"com.saurik."]) return YES;
    return NO;
}

@implementation TFEngine

+ (instancetype)shared {
    static TFEngine *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [TFEngine new]; });
    return s;
}

- (void)telegramDidBecomeActive {
    TFPrefs *p = TFPrefs.shared;
    if (!p.enabled) return;

    if (p.freezeOtherApps) {
        [self suspendOtherUserApps];
    }
    if (p.aggressiveMemory) {
        [self trimMemoryIfNeeded];
    }
}

- (void)telegramDidResignActive {
    // Nothing destructive — other apps wake naturally when user opens them.
}

- (void)suspendOtherUserApps {
    // Cross-process request: post Darwin notify so SpringBoard side can act.
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.telefocus.tweak/suspendOthers"),
        NULL, NULL, true);
}

- (void)trimMemoryIfNeeded {
    // Ask this process (Telegram) to drop caches when possible.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    // Soft purge of image memory by posting memory warning to self
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[UIApplication sharedApplication] performSelector:@selector(_performMemoryWarning)];
#pragma clang diagnostic pop
}

@end
