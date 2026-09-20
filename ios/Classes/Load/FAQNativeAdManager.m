//
//  FAQNativeAdManager.m
//  flutter_qq_ads
//

#import "FAQNativeAdManager.h"

@interface FAQNativeAdManager()
@property (strong, nonatomic) NSMutableDictionary<NSNumber *, id> *nativeAdList;
@end

@implementation FAQNativeAdManager

+ (instancetype)share {
    static FAQNativeAdManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FAQNativeAdManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _nativeAdList = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)putAd:(NSNumber *)key value:(id)value {
    if (key != nil && value != nil) {
        [self.nativeAdList setObject:value forKey:key];
    }
}

- (id)getAd:(NSNumber *)key {
    return [self.nativeAdList objectForKey:key];
}

- (id)removeAd:(NSNumber *)key {
    id value = [self.nativeAdList objectForKey:key];
    if (value != nil) {
        [self.nativeAdList removeObjectForKey:key];
    }
    return value;
}

@end
