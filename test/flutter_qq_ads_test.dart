import 'package:flutter/services.dart';
import 'package:flutter_qq_ads/flutter_qq_ads.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ads_config.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_qq_ads');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      final String method = call.method;
      if (method == 'initAd') {
        final String appId = call.arguments['appId'] ?? '';
        return appId.isNotEmpty;
      } else if (method == 'setPersonalizedState') {
        final int state = call.arguments['state'] ?? 0;
        return state == 0 || state == 1;
      } else if (method == 'showSplashAd') {
        final String posId = call.arguments['posId'] ?? '';
        return posId.isNotEmpty;
      } else if (method == 'showInterstitialAd') {
        final String posId = call.arguments['posId'] ?? '';
        return posId.isNotEmpty;
      } else if (method == 'showRewardVideoAd') {
        final String posId = call.arguments['posId'] ?? '';
        return posId.isNotEmpty;
      } else if (method == 'loadNativeAd') {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'adId': 1001,
            'title': 'Native title',
            'desc': 'Native desc',
            'iconUrl': 'https://example.com/icon.png',
            'imgUrls': <String>['https://example.com/image.png'],
            'buttonText': '立即查看',
            'source': '优量汇',
            'patternType': 'NATIVE_1IMAGE_2TEXT',
            'ecpm': 120,
            'isAppAd': true,
          },
        ];
      } else if (method == 'clearNativeAd') {
        final List<dynamic> list = call.arguments['list'] ?? <dynamic>[];
        return list.isNotEmpty;
      }
      return false;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initAd', () async {
    expect(await FlutterQqAds.initAd(AdsConfig.appId), true);
  });

  test('setPersonalizedState', () async {
    expect(await FlutterQqAds.setPersonalizedState(1), true);
  });
  test('showSplashAd', () async {
    expect(await FlutterQqAds.showSplashAd(AdsConfig.splashId), true);
  });
  test('showInterstitialAd', () async {
    expect(
        await FlutterQqAds.showInterstitialAd(AdsConfig.interstitialId), true);
    expect(
        await FlutterQqAds.showInterstitialAd(
            AdsConfig.interstitialFullScreenVideoId),
        true);
    expect(
        await FlutterQqAds.showInterstitialAd(
            AdsConfig.interstitialRewardVideoId),
        true);
  });
  test('showRewardVideoAd', () async {
    expect(await FlutterQqAds.showRewardVideoAd(AdsConfig.rewardVideoId), true);
  });

  test('loadNativeAd', () async {
    final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd(
      AdsConfig.interstitialId,
      count: 2,
    );

    expect(ads, hasLength(1));
    expect(ads.first.adId, 1001);
    expect(ads.first.title, 'Native title');
    expect(ads.first.patternType, 'NATIVE_1IMAGE_2TEXT');
    expect(ads.first.ecpm, 120);
    expect(ads.first.isAppAd, true);
  });

  test('clearNativeAd', () async {
    expect(await FlutterQqAds.clearNativeAd(<int>[1001, 1002]), true);
  });

  test('AdNativeWidget exposes title and desc width overrides', () {
    const AdNativeWidget widget = AdNativeWidget(
      adId: 1001,
      titleWidth: 120,
      descWidth: 110,
    );

    expect(widget.titleWidth, 120);
    expect(widget.descWidth, 110);
  });

  test('NativeAdStyle exposes supported native style values', () {
    expect(NativeAdStyle.verticalListNative.value, 'verticalListNative');
    expect(NativeAdStyle.horizontalListNative.value, 'horizontalListNative');
    expect(
      NativeAdStyle.bannerOnlyImageNative.value,
      'bannerOnlyImageNative',
    );
  });

  test('AdNativeWidget defaults to vertical native style', () {
    const AdNativeWidget widget = AdNativeWidget(
      adId: 1001,
    );

    expect(widget.styleType, NativeAdStyle.verticalListNative);
  });

  test('AdNativeWidget exposes native layout controls', () {
    const AdNativeWidget widget = AdNativeWidget(
      adId: 1001,
      width: 320,
      height: 112,
      styleType: NativeAdStyle.verticalListNative,
      isOnlyTitle: true,
      descMaxLines: 3,
      titleWidth: 120,
      descWidth: 110,
      imageWidth: 180,
      imageHeight: 120,
      imageRadius: 20,
    );

    expect(widget.width, 320);
    expect(widget.height, 112);
    expect(widget.styleType, NativeAdStyle.verticalListNative);
    expect(widget.isOnlyTitle, isTrue);
    expect(widget.descMaxLines, 3);
    expect(widget.titleWidth, 120);
    expect(widget.descWidth, 110);
    expect(widget.imageWidth, 180);
    expect(widget.imageHeight, 120);
    expect(widget.imageRadius, 20);
  });

  test('AdNativeWidget native creation params include strict layout controls',
      () {
    const AdNativeWidget widget = AdNativeWidget(
      adId: 1001,
      width: 320,
      height: 112,
      styleType: NativeAdStyle.horizontalListNative,
      isOnlyTitle: true,
      descMaxLines: 3,
      titleWidth: 120,
      descWidth: 110,
      imageWidth: 180,
      imageHeight: 98,
      imageRadius: 20,
    );

    expect(widget.debugCreationParams, <String, dynamic>{
      'posId': '1001',
      'width': 320.0,
      'height': 112.0,
      'styleType': 'horizontalListNative',
      'isOnlyTitle': true,
      'descMaxLines': 3,
      'titleWidth': 120.0,
      'descWidth': 110.0,
      'imageWidth': 180.0,
      'imageHeight': 98.0,
      'imageRadius': 20.0,
    });
  });

  test('horizontalListNative keeps left-image right-text layout params', () {
    const AdNativeWidget widget = AdNativeWidget(
      adId: 1001,
      width: 375,
      height: 112,
      styleType: NativeAdStyle.horizontalListNative,
      descMaxLines: 2,
      titleWidth: 175,
      descWidth: 175,
      imageWidth: 74,
      imageHeight: 98,
      imageRadius: 4,
    );

    expect(widget.styleType, NativeAdStyle.horizontalListNative);
    expect(widget.debugCreationParams['titleWidth'], 175.0);
    expect(widget.debugCreationParams['descWidth'], 175.0);
    expect(widget.debugCreationParams['imageWidth'], 74.0);
    expect(widget.debugCreationParams['imageHeight'], 98.0);
  });

  test('AdNativeWidget platform view key changes when layout params change',
      () {
    const AdNativeWidget compactWidget = AdNativeWidget(
      adId: 1001,
      width: 320,
      height: 112,
      imageWidth: 74,
      imageHeight: 98,
    );
    const AdNativeWidget wideWidget = AdNativeWidget(
      adId: 1001,
      width: 320,
      height: 112,
      imageWidth: 180,
      imageHeight: 98,
    );

    expect(
      compactWidget.debugPlatformViewKey,
      isNot(wideWidget.debugPlatformViewKey),
    );
  });

  test('AdNativeWidget exposes new homepage native style types', () {
    const AdNativeWidget verticalWidget = AdNativeWidget(
      adId: 1001,
      styleType: NativeAdStyle.verticalListNative,
    );
    const AdNativeWidget horizontalWidget = AdNativeWidget(
      adId: 1002,
      styleType: NativeAdStyle.horizontalListNative,
    );
    const AdNativeWidget bannerWidget = AdNativeWidget(
      adId: 1003,
      styleType: NativeAdStyle.bannerOnlyImageNative,
    );

    expect(verticalWidget.styleType, NativeAdStyle.verticalListNative);
    expect(horizontalWidget.styleType, NativeAdStyle.horizontalListNative);
    expect(bannerWidget.styleType, NativeAdStyle.bannerOnlyImageNative);
  });
}
