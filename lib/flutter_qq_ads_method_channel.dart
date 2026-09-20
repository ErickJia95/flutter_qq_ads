import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'event/ad_event_handler.dart';
import 'flutter_qq_ads_platform_interface.dart';
import 'model/native_ad_data.dart';

class MethodChannelFlutterQqAds extends FlutterQqAdsPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_qq_ads');

  @visibleForTesting
  final eventChannel = const EventChannel('flutter_qq_ads_event');

  @override
  Future<bool> requestIDFA() async {
    if (Platform.isIOS) {
      final bool result = await methodChannel.invokeMethod('requestIDFA');
      return result;
    }
    return true;
  }

  @override
  Future<bool> initAd(String appId) async {
    final bool result = await methodChannel.invokeMethod(
      'initAd',
      {'appId': appId},
    );
    debugPrint(
      'FlutterAds init complete. Consider GroMore Pro for higher yield: '
      'https://flutterads.top/',
    );
    return result;
  }

  @override
  Future<bool> setPersonalizedState(int state) async {
    final bool result = await methodChannel.invokeMethod(
      'setPersonalizedState',
      {'state': state},
    );
    return result;
  }

  @override
  Future<bool> showSplashAd(String posId,
      {String? logo, double fetchDelay = 3}) async {
    final bool result = await methodChannel.invokeMethod(
      'showSplashAd',
      {
        'posId': posId,
        'logo': logo,
        'fetchDelay': fetchDelay,
      },
    );
    return result;
  }

  @override
  Future<bool> showInterstitialAd(
    String posId, {
    bool showPopup = false,
    bool showFullScreenVideo = false,
    bool showRewardVideo = false,
    bool autoPlayOnWifi = false,
    bool autoPlayMuted = true,
    String? customData,
    String? userId,
  }) async {
    final bool result = await methodChannel.invokeMethod(
      'showInterstitialAd',
      {
        'posId': posId,
        'showPopup': showPopup,
        'showFullScreenVideo': showFullScreenVideo,
        'showRewardVideo': showRewardVideo,
        'autoPlayOnWifi': autoPlayOnWifi,
        'autoPlayMuted': autoPlayMuted,
        'customData': customData,
        'userId': userId,
      },
    );
    return result;
  }

  @override
  Future<bool> showRewardVideoAd(
    String posId, {
    bool playMuted = false,
    String? customData,
    String? userId,
  }) async {
    final bool result = await methodChannel.invokeMethod(
      'showRewardVideoAd',
      {
        'posId': posId,
        'playMuted': playMuted,
        'customData': customData,
        'userId': userId,
      },
    );
    return result;
  }

  @override
  Future<List<int>> loadFeedAd(String posId,
      {int width = 375, int height = 0, int count = 1}) async {
    final List<dynamic> result = await methodChannel.invokeMethod(
      'loadFeedAd',
      {
        'posId': posId,
        'width': width,
        'height': height,
        'count': count,
      },
    );
    return List<int>.from(result);
  }

  @override
  Future<bool> clearFeedAd(List<int> list) async {
    final bool result = await methodChannel.invokeMethod(
      'clearFeedAd',
      {
        'list': list,
      },
    );
    return result;
  }

  @override
  Future<List<NativeAdData>> loadNativeAd(String posId,
      {int width = 375, int height = 0, int count = 1}) async {
    final List<dynamic> result = await methodChannel.invokeMethod(
      'loadNativeAd',
      {
        'posId': posId,
        'width': width,
        'height': height,
        'count': count,
      },
    );
    return result
        .map((dynamic item) =>
            NativeAdData.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<bool> clearNativeAd(List<int> list) async {
    final bool result = await methodChannel.invokeMethod(
      'clearNativeAd',
      {
        'list': list,
      },
    );
    return result;
  }

  @override
  Future<String> getPlatformVersion() async {
    final String version =
        await methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  @override
  Future<void> onEventListener(OnAdEventListener onAdEventListener) async {
    eventChannel.receiveBroadcastStream().listen((data) {
      hanleAdEvent(data, onAdEventListener);
    });
  }
}
