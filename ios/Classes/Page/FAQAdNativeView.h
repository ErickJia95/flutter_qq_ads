//
//  FAQAdNativeView.h
//  flutter_qq_ads
//

#import <Flutter/Flutter.h>
#import "FlutterQqAdsPlugin.h"
#import "FAQBaseAdPage.h"

@interface FAQAdNativeView : FAQBaseAdPage<FlutterPlatformView>
- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger
                       plugin:(FlutterQqAdsPlugin *)plugin;
@end
