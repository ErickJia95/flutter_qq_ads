#import <TargetConditionals.h>
#if TARGET_OS_SIMULATOR
// ZW_ARM64_SIMULATOR_STUB
#import "FAQAdNativeView.h"

@interface FAQAdNativeView ()
@property(nonatomic, strong) UIView *stubView;
@end

@implementation FAQAdNativeView
- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger
                       plugin:(FlutterQqAdsPlugin *)plugin {
    self = [super init];
    if (self) {
        self.stubView = [[UIView alloc] initWithFrame:frame];
        self.stubView.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (UIView *)view {
    return self.stubView ?: [[UIView alloc] initWithFrame:CGRectZero];
}
@end

#else
//
//  FAQAdNativeView.m
//  flutter_qq_ads
//

#import "FAQAdNativeView.h"
#import "FAQNativeAdManager.h"
#import <GDTMobSDK/GDTUnifiedNativeAdDataObject.h>
#import <GDTMobSDK/GDTUnifiedNativeAdView.h>

static NSString *const kFAQNativeStyleVerticalListNative = @"verticalListNative";
static NSString *const kFAQNativeStyleHorizontalListNative = @"horizontalListNative";
static NSString *const kFAQNativeStyleBannerOnlyImageNative = @"bannerNative";

@interface FAQAdNativeView()<GDTUnifiedNativeAdViewDelegate>
@property (strong, nonatomic) UIView *nativeView;
@property (strong, nonatomic) GDTUnifiedNativeAdView *adView;
@property (strong, nonatomic) GDTUnifiedNativeAdDataObject *adData;
@property (copy, nonatomic) NSString *styleType;
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) NSMutableArray<UIImageView *> *mediaViews;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descLabel;
@property (strong, nonatomic) UILabel *sourceLabel;
@property (strong, nonatomic) UIButton *actionButton;
@property (assign, nonatomic) BOOL isOnlyTitle;
@property (assign, nonatomic) NSInteger descMaxLines;
@property (assign, nonatomic) CGFloat viewWidth;
@property (assign, nonatomic) CGFloat viewHeight;
@property (assign, nonatomic) CGFloat titleWidth;
@property (assign, nonatomic) CGFloat descWidth;
@property (assign, nonatomic) CGFloat imageWidth;
@property (assign, nonatomic) CGFloat imageHeight;
@property (assign, nonatomic) CGFloat imageRadius;
@end

@implementation FAQAdNativeView

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger
                       plugin:(FlutterQqAdsPlugin *)plugin {
    self = [super init];
    if (self) {
        self.nativeView = [[UIView alloc] initWithFrame:frame];
        self.nativeView.backgroundColor = UIColor.clearColor;
        self.mediaViews = [NSMutableArray array];
        self.isOnlyTitle = NO;
        self.descMaxLines = 0;
        self.viewWidth = 0;
        self.viewHeight = 0;
        self.titleWidth = 0;
        self.descWidth = 0;
        self.imageWidth = 0;
        self.imageHeight = 0;
        self.imageRadius = 0;
        NSString *style = [args isKindOfClass:[NSDictionary class]] ? [args[@"styleType"] description] : nil;
        self.styleType = [self resolveStyleType:style];
        if ([args isKindOfClass:[NSDictionary class]]) {
            self.isOnlyTitle = [self parseBoolean:args[@"isOnlyTitle"]];
            self.descMaxLines = [self parseDescMaxLines:args[@"descMaxLines"]];
            self.viewWidth = [self parseDimension:args[@"width"]];
            self.viewHeight = [self parseDimension:args[@"height"]];
            self.titleWidth = [self parseDimension:args[@"titleWidth"]];
            self.descWidth = [self parseDimension:args[@"descWidth"]];
            self.imageWidth = [self parseDimension:args[@"imageWidth"]];
            self.imageHeight = [self parseDimension:args[@"imageHeight"]];
            self.imageRadius = [self parseDimension:args[@"imageRadius"]];
        }
        if (self.viewWidth > 0 || self.viewHeight > 0) {
            CGRect nativeFrame = self.nativeView.frame;
            if (self.viewWidth > 0) {
                nativeFrame.size.width = self.viewWidth;
            }
            if (self.viewHeight > 0) {
                nativeFrame.size.height = self.viewHeight;
            }
            self.nativeView.frame = nativeFrame;
            self.nativeView.clipsToBounds = YES;
        }
        FlutterMethodCall *call = [FlutterMethodCall methodCallWithMethodName:@"AdNativeView" arguments:args];
        [self showAd:call eventSink:plugin.eventSink];
    }
    return self;
}

- (UIView *)view {
    return self.nativeView;
}

- (void)loadAd:(FlutterMethodCall *)call {
    NSNumber *key = @([self.posId integerValue]);
    self.adData = [FAQNativeAdManager.share getAd:key];
    if (self.adData == nil || !self.adData.isAdValid) {
        [self sendErrorEvent:-101 withErrMsg:@"native ad not found"];
        return;
    }
    [self renderView];
}

- (void)renderView {
    [self.nativeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.mediaViews removeAllObjects];

    CGRect layoutFrame = [self resolvedLayoutFrame];
    self.adView = [[GDTUnifiedNativeAdView alloc] initWithFrame:layoutFrame];
    self.adView.delegate = self;
    self.adView.backgroundColor = UIColor.clearColor;
    self.adView.clipsToBounds = YES;
    self.adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.nativeView addSubview:self.adView];

    UIView *cardView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(layoutFrame), CGRectGetHeight(layoutFrame))];
    cardView.backgroundColor = [UIColor colorWithRed:1.0 green:0.972 blue:0.945 alpha:1.0];
    cardView.layer.cornerRadius = 16.0;
    cardView.layer.masksToBounds = YES;
    cardView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.adView addSubview:cardView];

    if ([self.styleType isEqualToString:kFAQNativeStyleHorizontalListNative]) {
        [self buildHorizontalListLayoutInView:cardView];
    } else if ([self.styleType isEqualToString:kFAQNativeStyleBannerOnlyImageNative]) {
        [self buildBannerOnlyImageLayoutInView:cardView];
    } else {
        [self buildVerticalListLayoutInView:cardView];
    }

    [self registerAdData];
    [self loadImage:self.adData.iconUrl into:self.iconView];
}

- (CGRect)resolvedLayoutFrame {
    CGRect frame = self.nativeView.bounds;
    if (self.viewWidth > 0) {
        frame.size.width = self.viewWidth;
    }
    if (self.viewHeight > 0) {
        frame.size.height = self.viewHeight;
    }
    return frame;
}

- (void)buildVerticalListLayoutInView:(UIView *)cardView {
    [self buildImageTextDownloadLayoutInView:cardView];
}

- (void)buildHorizontalListLayoutInView:(UIView *)cardView {
    [self buildWideStripLayoutInView:cardView];
}

- (void)buildBannerOnlyImageLayoutInView:(UIView *)cardView {
    CGFloat width = CGRectGetWidth(cardView.bounds);
    CGFloat height = CGRectGetHeight(cardView.bounds);

    CGFloat horizontalPadding = 12;
    CGFloat imageWidth = self.imageWidth > 0 ? self.imageWidth : width - horizontalPadding * 2;
    CGFloat imageHeight = self.imageHeight > 0 ? self.imageHeight : height - horizontalPadding * 2;
    CGFloat imageRadius = self.imageRadius > 0 ? self.imageRadius : 16;
    CGFloat imageX = (width - imageWidth) / 2.0;
    CGFloat imageY = (height - imageHeight) / 2.0;

    UIView *imageShell = [[UIView alloc] initWithFrame:CGRectMake(imageX, imageY, imageWidth, imageHeight)];
    [cardView addSubview:imageShell];

    UIImageView *mediaView = [self createMediaView:CGRectMake(0, 0, imageWidth, imageHeight) radius:imageRadius];
    mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [imageShell addSubview:mediaView];
    [self.mediaViews addObject:mediaView];

    [self loadImage:[self primaryImageURL] into:mediaView];
}

- (void)buildWideStripLayoutInView:(UIView *)cardView {
    CGFloat width = CGRectGetWidth(cardView.bounds);
    CGFloat height = CGRectGetHeight(cardView.bounds);
    CGFloat horizontalPadding = 12;
    CGFloat verticalPadding = 12;
    CGFloat imageWidth = self.imageWidth > 0 ? self.imageWidth : 96;
    CGFloat maxImageHeight = MAX(height - verticalPadding * 2, 0);
    CGFloat imageHeight = self.imageHeight > 0 ? MIN(self.imageHeight, maxImageHeight) : maxImageHeight;
    CGFloat imageRadius = self.imageRadius > 0 ? self.imageRadius : 18;
    CGFloat imageY = verticalPadding + MAX((maxImageHeight - imageHeight) / 2.0, 0);

    UIView *imageShell = [[UIView alloc] initWithFrame:CGRectMake(horizontalPadding, imageY, imageWidth, imageHeight)];
    [cardView addSubview:imageShell];

    UIImageView *mediaView = [self createMediaView:CGRectMake(0, 0, imageWidth, imageHeight) radius:imageRadius];
    mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [imageShell addSubview:mediaView];
    [self.mediaViews addObject:mediaView];

    CGFloat textX = CGRectGetMaxX(imageShell.frame) + 12;
    CGFloat availableTextWidth = MAX(width - textX - horizontalPadding, 60);
    CGFloat titleWidth = self.titleWidth > 0 ? MIN(self.titleWidth, availableTextWidth) : availableTextWidth;
    CGFloat descWidth = self.descWidth > 0 ? MIN(self.descWidth, availableTextWidth) : availableTextWidth;
    NSInteger descLines = [self resolveDescMaxLinesWithDefault:2];
    UIFont *titleFont = [UIFont boldSystemFontOfSize:16];
    UIFont *descFont = [UIFont systemFontOfSize:12];
    CGFloat titleHeight = ceil(titleFont.lineHeight);
    CGFloat descHeight = self.isOnlyTitle ? 0 : ceil(descFont.lineHeight) * descLines;
    CGFloat contentHeight = titleHeight + (self.isOnlyTitle ? 0 : 6 + descHeight);
    CGFloat textY = verticalPadding + MAX((height - verticalPadding * 2 - contentHeight) / 2.0, 0);

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(textX, textY, titleWidth, titleHeight)];
    self.titleLabel.textColor = [UIColor colorWithRed:0.165 green:0.133 blue:0.196 alpha:1.0];
    self.titleLabel.font = titleFont;
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.text = self.adData.title ?: @"";
    [cardView addSubview:self.titleLabel];

    if (!self.isOnlyTitle) {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(textX, CGRectGetMaxY(self.titleLabel.frame) + 6, descWidth, descHeight)];
        self.descLabel.textColor = [UIColor colorWithRed:0.471 green:0.427 blue:0.529 alpha:1.0];
        self.descLabel.font = descFont;
        self.descLabel.numberOfLines = descLines;
        self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.descLabel.text = self.adData.desc ?: @"";
        [cardView addSubview:self.descLabel];
    } else {
        self.descLabel = nil;
    }

    [self loadImage:[self primaryImageURL] into:mediaView];
}

- (void)buildImageTextDownloadLayoutInView:(UIView *)cardView {
    CGFloat width = CGRectGetWidth(cardView.bounds);
    CGFloat height = CGRectGetHeight(cardView.bounds);
    CGFloat horizontalPadding = 12;
    CGFloat imageWidth = self.imageWidth > 0 ? self.imageWidth : width - horizontalPadding * 2;
    CGFloat imageHeight = self.imageHeight > 0 ? self.imageHeight : 148;
    CGFloat imageRadius = self.imageRadius > 0 ? self.imageRadius : 18;
    CGFloat imageX = self.imageWidth > 0 ? (width - imageWidth) / 2.0 : horizontalPadding;

    UIView *imageShell = [[UIView alloc] initWithFrame:CGRectMake(imageX, horizontalPadding, imageWidth, imageHeight)];
    [cardView addSubview:imageShell];

    UIImageView *mediaView = [self createMediaView:CGRectMake(0, 0, imageWidth, imageHeight) radius:imageRadius];
    mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [imageShell addSubview:mediaView];
    [self.mediaViews addObject:mediaView];

    CGFloat contentY = CGRectGetMaxY(imageShell.frame) + 12;
    CGFloat contentHeight = MAX(height - contentY - horizontalPadding, 72);
    CGFloat buttonWidth = 84;
    CGFloat buttonHeight = 34;
    CGFloat textMaxWidth = MAX(width - horizontalPadding * 3 - buttonWidth, 60);
    CGFloat textWidth = self.titleWidth > 0 ? MIN(self.titleWidth, textMaxWidth) : textMaxWidth;
    CGFloat descWidth = self.descWidth > 0 ? MIN(self.descWidth, textMaxWidth) : textWidth;
    UIFont *titleFont = [UIFont boldSystemFontOfSize:16];
    UIFont *descFont = [UIFont systemFontOfSize:12];
    NSInteger descLines = [self resolveDescMaxLinesWithDefault:2];
    CGFloat titleHeight = self.isOnlyTitle ? 44 : 22;
    CGFloat descLineHeight = ceil(descFont.lineHeight);
    CGFloat descHeight = self.isOnlyTitle ? 0 : MIN(descLineHeight * descLines, MAX(contentHeight - 6, descLineHeight));
    CGFloat textBlockHeight = titleHeight + (self.isOnlyTitle ? 0 : 6 + descHeight);
    CGFloat textY = contentY + MAX((contentHeight - textBlockHeight) / 2.0, 0);

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding, textY, textWidth, titleHeight)];
    self.titleLabel.textColor = [UIColor colorWithRed:0.165 green:0.133 blue:0.196 alpha:1.0];
    self.titleLabel.font = titleFont;
    self.titleLabel.numberOfLines = self.isOnlyTitle ? 3 : 2;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.text = self.adData.title ?: @"";
    [cardView addSubview:self.titleLabel];

    if (!self.isOnlyTitle) {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding, CGRectGetMaxY(self.titleLabel.frame) + 6, descWidth, descHeight)];
        self.descLabel.textColor = [UIColor colorWithRed:0.471 green:0.427 blue:0.529 alpha:1.0];
        self.descLabel.font = descFont;
        self.descLabel.numberOfLines = descLines;
        self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.descLabel.text = self.adData.desc ?: @"";
        [cardView addSubview:self.descLabel];
    } else {
        self.descLabel = nil;
    }

    CGFloat buttonY = contentY + MAX((contentHeight - buttonHeight) / 2.0, 0);
    CGFloat buttonX = width - horizontalPadding - buttonWidth;
    self.actionButton = [self createActionButton:CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight) preferDownloadFallback:YES];
    self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [cardView addSubview:self.actionButton];

    [self loadImage:[self primaryImageURL] into:mediaView];
}

- (UIView *)buildBadgeRow:(CGRect)frame {
    UIView *row = [[UIView alloc] initWithFrame:frame];

    UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 42, 18)];
    badgeLabel.text = @"广告";
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    badgeLabel.textColor = [UIColor colorWithRed:0.933 green:0.498 blue:0.149 alpha:1.0];
    badgeLabel.font = [UIFont boldSystemFontOfSize:11];
    badgeLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.941 blue:0.875 alpha:1.0];
    badgeLabel.layer.cornerRadius = 9.0;
    badgeLabel.layer.masksToBounds = YES;
    [row addSubview:badgeLabel];

    self.sourceLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, CGRectGetWidth(frame) - 50, 18)];
    self.sourceLabel.textColor = [UIColor colorWithRed:0.631 green:0.561 blue:0.463 alpha:1.0];
    self.sourceLabel.font = [UIFont systemFontOfSize:11];
    self.sourceLabel.text = @"优量精选";
    [row addSubview:self.sourceLabel];

    return row;
}

- (UIView *)buildHeader:(CGRect)frame showIcon:(BOOL)showIcon compactText:(BOOL)compactText {
    UIView *header = [[UIView alloc] initWithFrame:frame];
    CGFloat textStartX = 0;
    if (showIcon) {
      self.iconView = [self createMediaView:CGRectMake(0, 4, 44, 44) radius:12];
      [header addSubview:self.iconView];
      textStartX = 54;
    }

    CGFloat actionWidth = compactText ? 76 : 84;
    CGFloat actionX = CGRectGetWidth(frame) - actionWidth;
    CGFloat textWidth = MAX(actionX - textStartX - 10, 60);

    CGFloat titleWidth = self.titleWidth > 0 ? self.titleWidth : textWidth;
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(textStartX, compactText ? 0 : 2, titleWidth, self.isOnlyTitle ? 48 : (compactText ? 38 : 22))];
    self.titleLabel.textColor = [UIColor colorWithRed:0.165 green:0.133 blue:0.196 alpha:1.0];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:(compactText ? 15 : 17)];
    self.titleLabel.numberOfLines = self.isOnlyTitle ? 3 : (compactText ? 2 : 1);
    self.titleLabel.text = self.adData.title ?: @"";
    [header addSubview:self.titleLabel];

    if (!self.isOnlyTitle) {
        NSInteger descLines = [self resolveDescMaxLinesWithDefault:(compactText ? 2 : 3)];
        CGFloat descWidth = self.descWidth > 0 ? self.descWidth : textWidth;
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(textStartX, compactText ? 38 : 28, descWidth, compactText ? MAX(CGRectGetHeight(frame) - 40, 24) : 30)];
        self.descLabel.textColor = [UIColor colorWithRed:0.471 green:0.427 blue:0.529 alpha:1.0];
        self.descLabel.font = [UIFont systemFontOfSize:(compactText ? 12 : 13)];
        self.descLabel.numberOfLines = descLines;
        self.descLabel.text = self.adData.desc ?: @"";
        [header addSubview:self.descLabel];
    } else {
        self.descLabel = nil;
    }

    self.actionButton = [self createActionButton:CGRectMake(actionX, compactText ? (CGRectGetHeight(frame) - 34) / 2.0 : 10, actionWidth, 34)];
    self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [header addSubview:self.actionButton];
    return header;
}

- (UIButton *)createActionButton:(CGRect)frame {
    return [self createActionButton:frame preferDownloadFallback:NO];
}

- (UIButton *)createActionButton:(CGRect)frame preferDownloadFallback:(BOOL)preferDownloadFallback {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.backgroundColor = [UIColor colorWithRed:0.933 green:0.553 blue:0.208 alpha:1.0];
    button.layer.cornerRadius = CGRectGetHeight(frame) / 2.0;
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [button setTitle:[self resolveActionButtonText:preferDownloadFallback] forState:UIControlStateNormal];
    return button;
}

- (NSString *)resolveActionButtonText {
    return [self resolveActionButtonText:NO];
}

- (NSString *)resolveActionButtonText:(BOOL)preferDownloadFallback {
    if (self.adData.buttonText.length > 0) {
        return self.adData.buttonText;
    }
    if (self.adData.callToAction.length > 0) {
        return self.adData.callToAction;
    }
    return preferDownloadFallback ? @"立即下载" : @"立即查看";
}

- (UIImageView *)createMediaView:(CGRect)frame radius:(CGFloat)radius {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = radius;
    imageView.backgroundColor = [UIColor colorWithRed:1.0 green:0.906 blue:0.831 alpha:1.0];
    return imageView;
}

- (NSInteger)resolveDescMaxLinesWithDefault:(NSInteger)defaultLines {
    return self.descMaxLines > 0 ? self.descMaxLines : defaultLines;
}

- (BOOL)parseBoolean:(id)rawValue {
    if (rawValue == nil || [rawValue isKindOfClass:[NSNull class]]) {
        return NO;
    }
    if ([rawValue respondsToSelector:@selector(boolValue)]) {
        return [rawValue boolValue];
    }
    NSString *stringValue = [[rawValue description] lowercaseString];
    return [stringValue isEqualToString:@"true"] || [stringValue isEqualToString:@"1"];
}

- (NSInteger)parseDescMaxLines:(id)rawValue {
    if (rawValue == nil || [rawValue isKindOfClass:[NSNull class]]) {
        return 0;
    }
    if ([rawValue respondsToSelector:@selector(integerValue)]) {
        NSInteger value = [rawValue integerValue];
        return value > 0 ? value : 0;
    }
    return 0;
}

- (CGFloat)parseDimension:(id)rawValue {
    if (rawValue == nil || [rawValue isKindOfClass:[NSNull class]]) {
        return 0;
    }
    if ([rawValue respondsToSelector:@selector(doubleValue)]) {
        CGFloat value = [rawValue doubleValue];
        return value > 0 ? value : 0;
    }
    return 0;
}

- (UILabel *)createOverlayBadgeLabel {
    UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 42, 18)];
    badgeLabel.text = @"广告";
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    badgeLabel.textColor = UIColor.whiteColor;
    badgeLabel.font = [UIFont boldSystemFontOfSize:11];
    badgeLabel.backgroundColor = [UIColor colorWithRed:0.122 green:0.137 blue:0.161 alpha:0.8];
    badgeLabel.layer.cornerRadius = 9.0;
    badgeLabel.layer.masksToBounds = YES;
    return badgeLabel;
}

- (NSString *)primaryImageURL {
    if (self.adData.imageUrl.length > 0) {
        return self.adData.imageUrl;
    }
    if (self.adData.iconUrl.length > 0) {
        return self.adData.iconUrl;
    }
    return @"";
}

- (NSString *)resolveStyleType:(NSString *)style {
    if ([style isEqualToString:kFAQNativeStyleHorizontalListNative]) {
        return kFAQNativeStyleHorizontalListNative;
    }
    if ([style isEqualToString:kFAQNativeStyleBannerOnlyImageNative]) {
        return kFAQNativeStyleBannerOnlyImageNative;
    }
    return kFAQNativeStyleVerticalListNative;
}

- (void)registerAdData {
    NSMutableArray<UIView *> *clickableViews = [NSMutableArray arrayWithObjects:self.adView, nil];
    if (self.iconView != nil) {
        [clickableViews addObject:self.iconView];
    }
    if (self.titleLabel != nil) {
        [clickableViews addObject:self.titleLabel];
    }
    if (self.descLabel != nil) {
        [clickableViews addObject:self.descLabel];
    }
    if (self.sourceLabel != nil) {
        [clickableViews addObject:self.sourceLabel];
    }
    if (self.actionButton != nil) {
        [clickableViews addObject:self.actionButton];
    }
    [clickableViews addObjectsFromArray:self.mediaViews];
    self.adView.viewController = self.rootController;
    [self.adView registerDataObject:self.adData clickableViews:clickableViews];
    if (self.actionButton != nil &&
        self.adData.callToAction.length > 0 &&
        self.adData.isAdValid) {
        [self.adView registerClickableCallToActionView:self.actionButton];
    }
}

- (void)dispose {
    [self.adView unregisterDataObject];
    [self.adView removeFromSuperview];
    if (self.adData != nil) {
        NSNumber *key = @([self.adData hash]);
        [FAQNativeAdManager.share removeAd:key];
    }
    self.adData = nil;
}

- (void)gdt_unifiedNativeAdViewWillExpose:(GDTUnifiedNativeAdView *)unifiedNativeAdView {
    [self sendEvent:[[FAQAdEvent alloc] initWithAdId:self.posId andAction:onAdExposure]];
}

- (void)gdt_unifiedNativeAdViewDidClick:(GDTUnifiedNativeAdView *)unifiedNativeAdView {
    [self sendEvent:[[FAQAdEvent alloc] initWithAdId:self.posId andAction:onAdClicked]];
}

- (void)gdt_unifiedNativeAdViewClosed:(GDTUnifiedNativeAdView *)unifiedNativeAdView {
    [self sendEvent:[[FAQAdEvent alloc] initWithAdId:self.posId andAction:onAdClosed]];
}

- (void)loadImage:(NSString *)urlString into:(UIImageView *)imageView {
    if (urlString.length == 0 || imageView == nil) {
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (url == nil) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        }
    });
}

@end

#endif
