//
//  FAQNativeAdManager.h
//  flutter_qq_ads
//

#import <Foundation/Foundation.h>

@interface FAQNativeAdManager : NSObject
+ (instancetype)share;
- (void)putAd:(NSNumber *)key value:(id)value;
- (id)getAd:(NSNumber *)key;
- (id)removeAd:(NSNumber *)key;
@end
