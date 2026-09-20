//
//  FAQNativeAdLoad.h
//  flutter_qq_ads
//

#import "FAQBaseAdPage.h"

@interface FAQNativeAdLoad : FAQBaseAdPage
- (void)loadNativeAdList:(FlutterMethodCall *)call result:(FlutterResult)result eventSink:(FlutterEventSink)events;
@end
