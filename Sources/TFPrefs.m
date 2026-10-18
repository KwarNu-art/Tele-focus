#import "TFPrefs.h"

static NSString * const kPath = @"/var/mobile/Library/Preferences/com.telefocus.tweak.plist";

@implementation TFPrefs {
    BOOL _enabled, _freezeOtherApps, _reduceAnimations, _reduceBlur, _lightChatUI, _aggressiveMemory;
    NSInteger _maxFPS;
}

+ (instancetype)shared {
    static TFPrefs *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [TFPrefs new]; [s reload]; });
    return s;
}

- (void)reload {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:kPath] ?: @{};
    id (^b)(NSString *, BOOL) = ^id(NSString *k, BOOL def) {
        id v = d[k]; return [v isKindOfClass:[NSNumber class]] ? v : @(def);
    };
    id (^i)(NSString *, NSInteger) = ^id(NSString *k, NSInteger def) {
        id v = d[k]; return [v isKindOfClass:[NSNumber class]] ? v : @(def);
    };
    _enabled = [b(@"enabled", YES) boolValue];
    _freezeOtherApps = [b(@"freezeOtherApps", YES) boolValue];
    _reduceAnimations = [b(@"reduceAnimations", YES) boolValue];
    _reduceBlur = [b(@"reduceBlur", YES) boolValue];
    _lightChatUI = [b(@"lightChatUI", YES) boolValue];
    _aggressiveMemory = [b(@"aggressiveMemory", YES) boolValue];
    _maxFPS = [i(@"maxFPS", 60) integerValue];
    if (_maxFPS > 60) _maxFPS = 60;
    if (_maxFPS < 0) _maxFPS = 0;
}

- (BOOL)enabled { return _enabled; }
- (BOOL)freezeOtherApps { return _freezeOtherApps; }
- (BOOL)reduceAnimations { return _reduceAnimations; }
- (BOOL)reduceBlur { return _reduceBlur; }
- (BOOL)lightChatUI { return _lightChatUI; }
- (BOOL)aggressiveMemory { return _aggressiveMemory; }
- (NSInteger)maxFPS { return _maxFPS; }

@end
