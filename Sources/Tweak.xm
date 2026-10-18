/*
 * TeleFocus — Telegram-only performance focus
 * Bundle: ph.telegra.Telegraph (+ SpringBoard helper)
 *
 * Honest goals:
 *  - Lighter UIKit work inside Telegram (animations, blur, heavy layers)
 *  - Optional FPS preference
 *  - While Telegram is foreground: ask SpringBoard to suspend other USER apps
 *  - Optional memory trim
 *
 * Not possible:
 *  - Guarantee 24h zero lag / zero crash (Telegram + network + RAM decide)
 *  - Silently delete Telegram features without reverse-engineering private TG APIs
 *  - 120 Hz on non-ProMotion panels
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "TFPrefs.h"
#import "TFEngine.h"

static BOOL TFInTelegram(void) {
    NSString *bid = [NSBundle mainBundle].bundleIdentifier ?: @"";
    return [bid isEqualToString:@"ph.telegra.Telegraph"];
}

static BOOL TFInSpringBoard(void) {
    NSString *bid = [NSBundle mainBundle].bundleIdentifier ?: @"";
    return [bid isEqualToString:@"com.apple.springboard"];
}

#pragma mark - Telegram-side: lighter UI

%group TelegramGroup

%hook CADisplayLink
- (void)addToRunLoop:(NSRunLoop *)rl forMode:(NSRunLoopMode)mode {
    TFPrefs *p = [TFPrefs shared];
    if (p.enabled && p.maxFPS > 0) {
        if (@available(iOS 10.0, *)) {
            self.preferredFramesPerSecond = (NSInteger)p.maxFPS;
        }
    }
    %orig;
}
- (void)setPreferredFramesPerSecond:(NSInteger)fps {
    TFPrefs *p = [TFPrefs shared];
    if (p.enabled && p.maxFPS > 0 && fps > p.maxFPS) fps = p.maxFPS;
    %orig(fps);
}
%end

%hook UIView
+ (void)setAnimationsEnabled:(BOOL)enabled {
    TFPrefs *p = [TFPrefs shared];
    if (p.enabled && p.reduceAnimations) {
        %orig(NO);
        return;
    }
    %orig;
}
- (void)didMoveToWindow {
    %orig;
    TFPrefs *p = [TFPrefs shared];
    if (!p.enabled || !p.lightChatUI) return;
    // Soften expensive layer work on large views
    if (self.window && self.layer.shadowOpacity > 0.01) {
        self.layer.shadowOpacity = 0;
        self.layer.shadowRadius = 0;
    }
}
%end

%hook UIVisualEffectView
- (void)setEffect:(UIVisualEffect *)effect {
    TFPrefs *p = [TFPrefs shared];
    if (p.enabled && p.reduceBlur && [effect isKindOfClass:[UIBlurEffect class]]) {
        %orig(nil);
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.28];
        return;
    }
    %orig;
}
%end

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
}

- (void)_applicationDidBecomeActive {
    %orig;
    [[TFPrefs shared] reload];
    [[TFEngine shared] telegramDidBecomeActive];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    [[TFPrefs shared] reload];
    [[TFEngine shared] telegramDidBecomeActive];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    %orig;
    [[TFEngine shared] telegramDidResignActive];
}
%end

// Periodic light trim while in Telegram (every 90s) — not aggressive kill loops
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    static CFTimeInterval last = 0;
    CFTimeInterval now = CACurrentMediaTime();
    if (now - last > 90.0) {
        last = now;
        TFPrefs *p = [TFPrefs shared];
        if (p.enabled && p.aggressiveMemory) {
            [[TFEngine shared] trimMemoryIfNeeded];
        }
    }
}
%end

%end // TelegramGroup

#pragma mark - SpringBoard helper: suspend other user apps

%group SpringBoardGroup

static void TFSuspendOthersCallback(CFNotificationCenterRef center, void *observer,
                                    CFStringRef name, const void *object,
                                    CFDictionaryRef userInfo) {
    TFPrefs *p = [TFPrefs shared];
    [p reload];
    if (!p.enabled || !p.freezeOtherApps) return;

    // Best-effort: use private SpringBoard API if available; otherwise no-op safely.
    // We intentionally do NOT kill system processes.
    Class SBAppClass = objc_getClass("SBApplicationController");
    if (!SBAppClass) return;
    id controller = [SBAppClass performSelector:@selector(sharedInstanceIfExists)];
    if (!controller) controller = [SBAppClass performSelector:@selector(sharedInstance)];
    if (!controller) return;

    // Prefer modern selector if present
    if ([controller respondsToSelector:@selector(allApplications)]) {
        NSArray *apps = [controller performSelector:@selector(allApplications)];
        for (id app in apps) {
            NSString *bid = nil;
            if ([app respondsToSelector:@selector(bundleIdentifier)]) {
                bid = [app performSelector:@selector(bundleIdentifier)];
            }
            if (!bid.length) continue;
            if ([bid hasPrefix:@"com.apple."]) continue;
            if ([bid isEqualToString:@"ph.telegra.Telegraph"]) continue;

            // Request suspension if API exists
            if ([app respondsToSelector:@selector(processState)]) {
                // no hard kill
            }
            // SBApplication may respond to kill / suspend — use soft path only
            SEL suspendSel = NSSelectorFromString(@"_suspendForReason:");
            if ([app respondsToSelector:suspendSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [app performSelector:suspendSel withObject:@"TeleFocus"];
#pragma clang diagnostic pop
            }
        }
    }
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg {
    %orig;
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        TFSuspendOthersCallback,
        CFSTR("com.telefocus.tweak/suspendOthers"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}
%end

%end // SpringBoardGroup

%ctor {
    @autoreleasepool {
        if (TFInTelegram()) {
            %init(TelegramGroup);
            [[TFPrefs shared] reload];
        } else if (TFInSpringBoard()) {
            %init(SpringBoardGroup);
            [[TFPrefs shared] reload];
        }
    }
}
