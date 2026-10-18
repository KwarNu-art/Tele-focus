#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFEngine : NSObject
+ (instancetype)shared;
- (void)telegramDidBecomeActive;
- (void)telegramDidResignActive;
- (void)trimMemoryIfNeeded;
@end

NS_ASSUME_NONNULL_END
