# flutter_qq_ads

[![pub package](https://img.shields.io/pub/v/flutter_qq_ads.svg)](https://pub.dev/packages/flutter_qq_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`flutter_qq_ads` 是腾讯优量汇（广点通）广告 SDK 的 Flutter 插件，支持 Android 和 iOS，提供开屏、插屏、激励视频、Banner、模板信息流和自渲染图文广告能力。

## 功能

- 开屏广告（Splash）
- 插屏广告（普通插屏、全屏视频、插屏激励视频）
- 激励视频广告
- Banner 广告 Widget
- 模板信息流广告加载与展示
- 自渲染图文广告加载与展示
- 个性化广告开关
- iOS 应用跟踪透明度（ATT）授权请求
- 统一的广告加载、曝光、点击、关闭、错误和激励事件回调

## 环境要求

- Flutter `>=2.5.0`
- Dart `>=2.17.0 <4.0.0`
- Android：最低 `minSdkVersion 19`；实际构建还需要满足当前 Flutter 和 Android Gradle Plugin 的要求
- iOS：插件 Podspec 当前最低部署版本为 iOS `11.0`

插件会自动引入平台广告 SDK。当前仓库中的依赖版本可以在以下位置查看：

- Android：`android/build.gradle` 的 `com.qq.e.union:union`
- iOS：`ios/flutter_qq_ads.podspec` 的 `GDTMobSDK`

发布或升级平台实现前，请以腾讯优量汇官方文档和官方依赖源的最新稳定版本为准，并同步验证 Android 与 iOS。不要把示例工程的 `Podfile.lock` 当作 SDK 版本来源。

## 安装

在应用的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter_qq_ads: ^2.9.6
```

然后执行：

```bash
flutter pub get
```

也可以执行：

```bash
flutter pub add flutter_qq_ads
```

## 平台配置

### Android

在宿主应用的 `android/app/src/main/AndroidManifest.xml` 中确认存在网络权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

应用媒体 ID 和广告位 ID 不需要写入 Manifest 或 Gradle，而是在 Dart 调用时传入。插件会自动合并广告 SDK 所需的 Activity、Provider 和资源配置。

### iOS

如果应用会请求 IDFA 或使用个性化广告，需在宿主应用的 `ios/Runner/Info.plist` 中添加 ATT 文案：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>为了向您提供更优质、安全的个性化服务及内容，需要您允许使用相关权限</string>
```

插件的 iOS Podspec 当前要求 iOS 11.0 或更高版本。安装或更新依赖时，在宿主工程执行：

```bash
cd ios
pod install --repo-update
```

## 快速开始

```dart
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

Future<void> setupAds() async {
  // 建议在 App 启动阶段初始化一次。
  final bool initialized = await FlutterQqAds.initAd('应用媒体 ID');
  if (!initialized) {
    return;
  }

  // 监听事件后再展示广告，便于处理错误和激励回调。
  await FlutterQqAds.onEventListener((AdEvent event) {
    print('adId: ${event.adId}, action: ${event.action}');

    if (event is AdErrorEvent) {
      print('error: ${event.errCode}, ${event.errMsg}');
    } else if (event is AdRewardEvent) {
      print('reward: ${event.transId}, userId: ${event.userId}');
    }
  });
}
```

`initAd` 的 `appId` 是优量汇应用媒体 ID，后续广告方法的 `posId` 是具体广告位 ID。请使用优量汇后台为对应平台创建的 ID。

## 广告调用

### 开屏广告

`fetchDelay` 默认 3 秒，支持范围为 1.5～5 秒。传入 `logo` 时展示底部 Logo，不传则使用全屏样式。

```dart
final bool result = await FlutterQqAds.showSplashAd(
  '开屏广告位 ID',
  logo: 'assets/logo.png', // 可选
  fetchDelay: 3,
);
```

### 插屏广告

```dart
await FlutterQqAds.showInterstitialAd(
  '插屏广告位 ID',
  showPopup: false,          // 仅 Android 有效
  showFullScreenVideo: true, // 全屏视频形式
  showRewardVideo: false,    // 插屏激励视频形式
  autoPlayOnWifi: false,
  autoPlayMuted: true,
  customData: 'server-data',
  userId: 'user-001',
);
```

### 激励视频

```dart
await FlutterQqAds.showRewardVideoAd(
  '激励视频广告位 ID',
  playMuted: false,
  customData: 'server-data',
  userId: 'user-001',
);
```

激励发放应在收到 `AdRewardEvent` 后处理，不要仅依据 `showRewardVideoAd` 的布尔返回值发放奖励。

### Banner 广告

`AdBannerWidget.posId` 使用广告位 ID。`interval` 为刷新间隔，Android 使用 `0` 表示不自动轮播；iOS 使用 `0` 表示关闭轮播动画。展示尺寸由宿主布局决定，下面示例使用 300×80：

```dart
AdBannerWidget(
  posId: 'Banner 广告位 ID',
  width: 300,
  height: 80,
  interval: 30,
  show: true,
)
```

### 模板信息流广告

模板信息流广告分为“加载缓存”和“展示 Widget”两步。`loadFeedAd` 返回的是广告实例 ID，不是广告位 ID；展示完成或页面销毁时调用 `clearFeedAd`。

```dart
final List<int> adIds = await FlutterQqAds.loadFeedAd(
  '信息流广告位 ID',
  width: 375,
  height: 0, // 0 表示由 SDK 自适应高度
  count: 1,
);

if (adIds.isNotEmpty) {
  AdFeedWidget(
    posId: '${adIds.first}',
    width: 375,
    height: 256,
  );
}

// 页面 dispose 或不再使用时释放缓存的广告实例。
await FlutterQqAds.clearFeedAd(adIds);
```

### 自渲染图文广告

`loadNativeAd` 返回 `NativeAdData`，通过 `AdNativeWidget` 交给原生侧渲染。支持三种样式：

- `NativeAdStyle.verticalListNative`：竖向图片、标题和描述
- `NativeAdStyle.horizontalListNative`：左图右文
- `NativeAdStyle.bannerOnlyImageNative`：仅展示图片

```dart
final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd(
  '自渲染广告位 ID',
  count: 1,
);

if (ads.isNotEmpty) {
  AdNativeWidget(
    adId: ads.first.adId,
    width: 375,
    height: 220,
    styleType: NativeAdStyle.verticalListNative,
    descMaxLines: 2,
    imageRadius: 8,
  );
}

await FlutterQqAds.clearNativeAd(
  ads.map((NativeAdData ad) => ad.adId).toList(),
);
```

`AdNativeWidget.adId` 必须是 `loadNativeAd` 返回的广告实例 ID，不能传广告位 ID。组件的 `width` 和 `height` 必须大于 0；不展示时可设置 `show: false`。

## 个性化广告与 IDFA

```dart
// 0：开启个性化广告推荐；1：关闭个性化广告推荐。
await FlutterQqAds.setPersonalizedState(1);

// iOS 请求 ATT 授权；Android 会直接返回 true。
final bool authorized = await FlutterQqAds.requestIDFA;
```

请在合适的用户交互时机请求 ATT 授权，并确保 `Info.plist` 已配置 `NSUserTrackingUsageDescription`。

## 事件回调

通过 `onEventListener` 接收广告事件：

```dart
FlutterQqAds.onEventListener((AdEvent event) {
  if (event.action == AdEventAction.onAdError && event is AdErrorEvent) {
    print('${event.errCode}: ${event.errMsg}');
  } else if (event.action == AdEventAction.onAdReward &&
      event is AdRewardEvent) {
    print('奖励流水号：${event.transId}');
  } else if (event.action == AdEventAction.onAdClosed) {
    print('广告已关闭');
  }
});
```

事件类型：

| 类型 | 说明 |
|---|---|
| `AdEvent` | 普通广告事件，包含 `adId` 和 `action` |
| `AdErrorEvent` | 错误事件，额外包含 `errCode` 和 `errMsg` |
| `AdRewardEvent` | 激励事件，额外包含 `transId`、`customData` 和 `userId` |

事件动作常量集中在 `AdEventAction`：`onAdLoaded`、`onAdPresent`、`onAdExposure`、`onAdClicked`、`onAdClosed`、`onAdComplete`、`onAdSkip`、`onAdError` 和 `onAdReward`。

## API 概览

| API | 用途 |
|---|---|
| `FlutterQqAds.initAd(appId)` | 初始化广告 SDK |
| `FlutterQqAds.requestIDFA` | 请求 iOS ATT/IDFA 授权 |
| `FlutterQqAds.setPersonalizedState(state)` | 设置个性化广告状态 |
| `FlutterQqAds.showSplashAd(posId, ...)` | 展示开屏广告 |
| `FlutterQqAds.showInterstitialAd(posId, ...)` | 展示插屏广告 |
| `FlutterQqAds.showRewardVideoAd(posId, ...)` | 展示激励视频 |
| `FlutterQqAds.loadFeedAd(posId, ...)` | 加载模板信息流实例 |
| `FlutterQqAds.clearFeedAd(list)` | 释放模板信息流实例 |
| `FlutterQqAds.loadNativeAd(posId, ...)` | 加载自渲染广告数据 |
| `FlutterQqAds.clearNativeAd(list)` | 释放自渲染广告实例 |
| `FlutterQqAds.onEventListener(callback)` | 注册广告事件监听 |

## 示例项目

仓库的 [`example/`](./example) 包含完整的广告演示页面和平台配置。运行示例：

```bash
cd example
flutter pub get
flutter run
```

示例中的测试广告位仅用于开发验证，正式应用请替换为自己在优量汇后台创建的应用媒体 ID 和广告位 ID。

## 开发与验证

```bash
flutter pub get
flutter analyze
flutter test
```

修改 Android 原生实现后，建议执行：

```bash
cd example
flutter build apk --debug
```

修改 iOS 原生实现后，在 macOS 且已安装 CocoaPods 的环境执行：

```bash
cd example/ios
pod install --repo-update
cd ..
flutter build ios --debug --no-codesign
```

## 常见问题

### 广告不展示

请依次检查：

1. 应用媒体 ID 和广告位 ID 是否属于当前平台且填写正确；
2. 是否已调用 `initAd` 且初始化成功；
3. Android 是否具备网络权限，设备网络是否正常；
4. 是否监听了 `AdErrorEvent` 并查看错误码和错误信息；
5. 测试广告位是否受到填充、频控或账户状态限制。

### 信息流或自渲染广告重复展示、退出页面后仍占用资源

保存 `loadFeedAd` / `loadNativeAd` 返回的实例 ID，在页面 `dispose` 或不再使用时分别调用 `clearFeedAd` / `clearNativeAd`。不要把广告位 ID 传给清除方法。

### iOS 无法请求 IDFA

确认 `Info.plist` 已配置 `NSUserTrackingUsageDescription`，并通过 `FlutterQqAds.requestIDFA` 请求授权。用户拒绝后，系统不会重复显示授权弹窗。

## 相关链接

- [优量汇开发者平台](https://e.qq.com/)
- [优量汇 Android SDK 文档](https://developers.qq.com/doc/oplatform/Mobile_SDK/Android_SDK.html)
- [优量汇 iOS SDK 文档](https://developers.qq.com/doc/oplatform/Mobile_SDK/iOS_SDK.html)
- [Android Maven 依赖版本](https://central.sonatype.com/artifact/com.qq.e.union/union/versions)
- [GDTMobSDK CocoaPods](https://cocoapods.org/pods/GDTMobSDK)
- [Flutter 官方文档](https://docs.flutter.dev/)
- [更新日志](./CHANGELOG.md)
- [使用补充说明](./use.md)

## 许可证与反馈

本项目采用 MIT License，详见 [LICENSE](./LICENSE)。

- 问题反馈：[GitHub Issues](https://github.com/FlutterAds/flutter_qq_ads/issues)
- 项目主页：[flutterads.top](https://flutterads.top)
