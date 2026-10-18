#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFPrefs : NSObject
+ (instancetype)shared;
- (void)reload;

@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, assign, readonly) BOOL freezeOtherApps;
@property (nonatomic, assign, readonly) BOOL reduceAnimations;
@property (nonatomic, assign, readonly) BOOL reduceBlur;
@property (nonatomic, assign, readonly) BOOL lightChatUI;
@property (nonatomic, assign, readonly) BOOL aggressiveMemory;
@property (nonatomic, assign, readonly) NSInteger maxFPS; // 0=off, 30, 60
@end

NS_ASSUME_NONNULL_END
