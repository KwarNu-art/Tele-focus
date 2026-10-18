/*
 * TeleFocus — Telegram-only performance focus
 * Target: ph.telegra.Telegraph + SpringBoard helper
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import "TFPrefs.h"
#import "TFEngine.h"

static BOOL TFInTelegram(void) {
    return [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"ph.telegra.Telegraph"];
}

static BOOL TFInSpringBoard(void) {
    return [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"];
}

#pragma mark - Telegram

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
    if (p.enabled && p.maxFPS > 0 && fps > p.maxFPS) {
        fps = p.maxFPS;
    }
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
    %orig(enabled);
}

- (void)didMoveToWindow {
    %orig;
    TFPrefs *p = [TFPrefs shared];
    if (!p.enabled || !p.lightChatUI) return;
    if (self.window && self.layer.shadowOpacity > 0.01f) {
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
    %orig(effect);
}

%end

%hook UIApplication

- (void)applicationDidBecomeActive:(id)application {
    %orig;
    [[TFPrefs shared] reload];
    [[TFEngine shared] telegramDidBecomeActive];
}

- (void)applicationWillResignActive:(id)application {
    %orig;
    [[TFEngine shared] telegramDidResignActive];
}

%end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    static CFTimeInterval lastTrim = 0;
    CFTimeInterval now = CACurrentMediaTime();
    if (now - lastTrim < 90.0) return;
    lastTrim = now;
    TFPrefs *p = [TFPrefs shared];
    if (p.enabled && p.aggressiveMemory) {
        [[TFEngine shared] trimMemoryIfNeeded];
    }
}

%end

%end // TelegramGroup

#pragma mark - SpringBoard helper

%group SpringBoardGroup

static void TFSuspendOthersCallback(CFNotificationCenterRef center, void *observer,
                                    CFStringRef name, const void *object,
                                    CFDictionaryRef userInfo) {
    (void)center; (void)observer; (void)name; (void)object; (void)userInfo;
    [[TFPrefs shared] reload];
    TFPrefs *p = [TFPrefs shared];
    if (!p.enabled || !p.freezeOtherApps) return;

    // Soft path only: notify system of memory pressure style cleanup is unsafe to fake.
    // Best-effort: if FBSystemService / SpringBoard private APIs exist, skip hard kills.
    // Intentionally minimal — stability over aggressive kill-all.
    NSLog(@"[TeleFocus] suspend-others signal received");
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
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
