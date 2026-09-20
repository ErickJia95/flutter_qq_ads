# flutter_qq_ads

[![pub package](https://img.shields.io/pub/v/flutter_qq_ads.svg)](https://pub.dev/packages/flutter_qq_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

【持续更新】一款优质的腾讯优量汇 Flutter 广告变现插件，支持 Android、iOS 平台，可快速接入进行广告变现。

## 功能特性

- ✅ 开屏广告 (Splash Ad)
- ✅ 插屏广告 (Interstitial Ad)
- ✅ 激励视频广告 (Reward Video Ad)
- ✅ 信息流广告 (Feed Ad)
- ✅ 自渲染图文广告 (Native Ad)
- ✅ Banner 广告 (Banner Ad)
- ✅ 个性化广告设置
- ✅ iOS IDFA 授权请求
- ✅ 完整的事件回调

## 平台支持

| 平台 | 支持状态 |
|------|----------|
| Android | ✅ |
| iOS | ✅ |

## 安装

在项目的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_qq_ads: ^2.9.6
```

或者使用命令行：

```bash
flutter pub add flutter_qq_ads
```

## Android 配置

### 1. 添加权限

在 `android/app/src/main/AndroidManifest.xml` 中添加必要权限：

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### 2. 配置应用 ID

在 `android/app/build.gradle` 的 `android.defaultConfig` 中配置应用 ID：

```groovy
defaultConfig {
    // 应用媒体ID
    manifestPlaceholders["APP_ID"] = "您的应用媒体ID"
    manifestPlaceholders["POS_ID"] = "您的广告位ID"
}
```

## iOS 配置

### 1. 添加依赖

在 `ios/Podfile` 中确保包含以下内容：

```ruby
platform :ios, '12.0'
```

### 2. 配置应用跟踪透明度

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>我们需要您的授权以向您展示个性化广告</string>
```

## 快速开始

### 1. 初始化广告 SDK

```dart
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

// 初始化广告
bool result = await FlutterQqAds.initAd('您的应用媒体ID');
```

### 2. 设置广告事件监听

```dart
// 设置广告事件监听
FlutterQqAds.onEventListener((event) {
  print('adId: ${event.adId}, action: ${event.action}');
  
  if (event is AdErrorEvent) {
    // 错误事件
    print('errCode: ${event.errCode}, errMsg: ${event.errMsg}');
  } else if (event is AdRewardEvent) {
    // 激励事件
    print('transId: ${event.transId}, userId: ${event.userId}');
  }
});
```

### 3. 展示开屏广告

```dart
// 展示开屏广告
await FlutterQqAds.showSplashAd(
  '您的广告位ID',
  logo: 'assets/logo.png', // 可选：底部 Logo
  fetchDelay: 3, // 可选：拉取超时时间
);
```

### 4. 展示插屏广告

```dart
// 展示插屏广告
await FlutterQqAds.showInterstitialAd(
  '您的广告位ID',
  showPopup: false,        // 是否 Popup 形式显示（仅 Android）
  showFullScreenVideo: false, // 是否全屏视频形式
  showRewardVideo: false,  // 是否激励视频形式
);
```

### 5. 展示激励视频广告

```dart
// 展示激励视频广告
await FlutterQqAds.showRewardVideoAd(
  '您的广告位ID',
  playMuted: false,  // 是否静音播放
  customData: '自定义数据',  // 服务端验证自定义信息
  userId: '用户ID',  // 服务端验证用户信息
);
```

### 6. 加载信息流广告

```dart
// 加载信息流广告
List<int> adIds = await FlutterQqAds.loadFeedAd(
  '您的广告位ID',
  width: 375,
  height: 0,  // 0 表示自适应高度
  count: 1,  // 建议 1~3 个
);

// 清除广告
await FlutterQqAds.clearFeedAd(adIds);
```

### 7. 使用信息流广告组件

```dart
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

// 使用信息流广告 Widget
AdFeedWidget(
  posId: '$adId',
  width: 375,
  height: 256,
)
```

### 8. 使用 Banner 广告组件

```dart
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

// 使用 Banner 广告 Widget
AdBannerWidget(
  posId: '您的广告位ID',
  width: 375,
  height: 50,
)
```

### 9. 使用自渲染图文广告

```dart
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd(
  '您的广告位ID',
  count: 1,
);

if (ads.isNotEmpty) {
  AdNativeWidget(
    adId: ads.first.adId,
    width: 375,
    height: 220,
    styleType: NativeAdStyle.verticalListNative,
  );
}
```

说明：

- 自渲染广告与模板信息流广告是两套独立能力
- 自渲染样式仅支持 `NativeAdStyle.verticalListNative`、`NativeAdStyle.horizontalListNative`、`NativeAdStyle.bannerOnlyImageNative`
- `NativeAdStyle.verticalListNative` 的底部信息区采用左侧文案、右侧操作按钮的对齐结构
- `NativeAdStyle.horizontalListNative` 为横向图文卡片，布局固定为左侧图片、右侧标题与描述
- 模板信息流仍使用 `loadFeedAd + AdFeedWidget`

## API 参考

### 核心方法

| 方法 | 说明 |
|------|------|
| `initAd(appId)` | 初始化广告 SDK |
| `setPersonalizedState(state)` | 设置个性化广告状态 (0: 开启, 1: 关闭) |
| `requestIDFA` | 请求 iOS IDFA 授权 |
| `showSplashAd(posId, ...)` | 展示开屏广告 |
| `showInterstitialAd(posId, ...)` | 展示插屏广告 |
| `showRewardVideoAd(posId, ...)` | 展示激励视频广告 |
| `loadFeedAd(posId, ...)` | 加载信息流广告 |
| `clearFeedAd(list)` | 清除信息流广告 |
| `loadNativeAd(posId, ...)` | 加载自渲染图文广告 |
| `clearNativeAd(list)` | 清除自渲染图文广告 |
| `onEventListener(callback)` | 设置广告事件监听 |

### 事件类型

| 事件 | 说明 |
|------|------|
| `AdEvent` | 基础广告事件 |
| `AdErrorEvent` | 广告错误事件 |
| `AdRewardEvent` | 激励广告事件 |

## 示例项目

请参考 [example](./example) 目录下的完整示例项目。

## 常见问题

### 1. 广告不显示怎么办？

- 检查应用媒体 ID 和广告位 ID 是否正确
- 检查网络连接是否正常
- 查看日志中的错误信息

### 2. iOS 激励视频无法播放？

- 确保已配置正确的广告位类型
- 检查是否在主线程调用

### 3. 如何获取更多广告位？

登录 [优量汇开发者平台](https://e.qq.com/) 创建广告位。

## 更新日志

详见 [CHANGELOG.md](./CHANGELOG.md)

## 相关链接

- [优量汇开发者平台](https://e.qq.com/)
- [优量汇 Android SDK 文档](https://developers.qq.com/doc/oplatform/Mobile_SDK/Android_SDK.html)
- [优量汇 iOS SDK 文档](https://developers.qq.com/doc/oplatform/Mobile_SDK/iOS_SDK.html)
- [Flutter 官方文档](https://flutter.dev/docs)

## 许可证

MIT License - 详见 [LICENSE](./LICENSE)

## 贡献者

感谢所有贡献者的支持！

## 联系方式

- 问题反馈：[GitHub Issues](https://github.com/FlutterAds/flutter_qq_ads/issues)
- 官方网站：[https://flutterads.top](https://flutterads.top)
