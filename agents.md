# 开发者指南 (agents.md)

本文档为 AI 代理和人类开发者提供项目开发指南。

## 项目概述

`flutter_qq_ads` 是一个 Flutter 广告插件，用于在 Flutter 应用中集成腾讯优量汇广告 SDK，支持 Android 和 iOS 平台。

## 技术栈

- **语言**: Dart, Java (Android), Objective-C (iOS)
- **框架**: Flutter
- **目标平台**: Android, iOS
- **最低 Flutter 版本**: 2.5.0
- **Dart SDK**: >=2.12.0 <4.0.0

## 项目结构

```
flutter_qq_ads/
├── lib/                          # Dart 源代码
│   ├── flutter_qq_ads.dart       # 主入口文件
│   ├── flutter_qq_ads_method_channel.dart  # Method Channel 实现
│   ├── flutter_qq_ads_platform_interface.dart  # 平台接口
│   ├── event/                    # 事件处理
│   │   ├── ad_event.dart         # 广告事件基类
│   │   ├── ad_error_event.dart   # 错误事件
│   │   ├── ad_event_action.dart  # 事件动作定义
│   │   ├── ad_event_handler.dart # 事件处理器
│   │   └── ad_reward_event.dart  # 激励事件
│   └── view/                     # 广告组件
│       ├── ad_banner_widget.dart # Banner 广告组件
│       └── ad_feed_widget.dart   # 信息流广告组件
├── android/                      # Android 原生代码
│   └── src/main/java/com/zero/flutter_qq_ads/
├── ios/                          # iOS 原生代码
│   └── Classes/
├── example/                      # 示例项目
└── test/                         # 单元测试
```

## 开发环境设置

### 1. 克隆项目

```bash
git clone https://github.com/FlutterAds/flutter_qq_ads.git
cd flutter_qq_ads
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行示例

```bash
cd example
flutter run
```

## 代码规范

### Dart 代码规范

1. **命名规范**
   - 类名使用 PascalCase: `FlutterQqAds`, `AdEvent`
   - 方法名和变量名使用 camelCase: `showSplashAd`, `adId`
   - 常量使用 k 开头: `kDefaultTimeout`
   - 私有成员使用下划线前缀: `_privateMethod`

2. **文档注释**
   - 所有公开 API 必须包含文档注释
   - 使用 `///` 格式的文档注释
   - 包含参数说明和返回值说明

   ```dart
   /// 初始化广告 SDK
   /// [appId] 应用媒体ID
   /// 返回是否初始化成功
   static Future<bool> initAd(String appId) {
     // ...
   }
   ```

3. **类型声明**
   - 优先使用类型声明，避免使用 `var`
   - 使用 `final` 声明不可变变量
   - 使用 `const` 声明编译时常量

4. **错误处理**
   - 使用 `try-catch` 捕获异常
   - 提供有意义的错误信息
   - 遵循 Flutter 错误处理最佳实践

### Android 代码规范 (Java)

1. 遵循 Google Java 风格指南
2. 使用 4 空格缩进
3. 类名使用 PascalCase
4. 方法名使用 camelCase

### iOS 代码规范 (Objective-C)

1. 遵循 Apple 编码规范
2. 使用 4 空格缩进
3. 方法名使用 camelCase，参数使用描述性名称

## 核心 API

### FlutterQqAds 类

```dart
class FlutterQqAds {
  /// 初始化广告 SDK
  static Future<bool> initAd(String appId);

  /// 设置个性化广告状态
  static Future<bool> setPersonalizedState(int state);

  /// 请求 iOS IDFA 授权
  static Future<bool> get requestIDFA;

  /// 展示开屏广告
  static Future<bool> showSplashAd(String posId, {String? logo, double fetchDelay});

  /// 展示插屏广告
  static Future<bool> showInterstitialAd(String posId, {bool showPopup, bool showFullScreenVideo, ...});

  /// 展示激励视频广告
  static Future<bool> showRewardVideoAd(String posId, {bool playMuted, String? customData, String? userId});

  /// 加载信息流广告
  static Future<List<int>> loadFeedAd(String posId, {int width, int height, int count});

  /// 清除信息流广告
  static Future<bool> clearFeedAd(List<int> list);

  /// 设置广告事件监听
  static Future<void> onEventListener(OnAdEventListener onAdEventListener);
}
```

## 添加新功能的步骤

### 1. 分析需求

- 理解功能需求
- 确定需要修改的平台（Android/iOS/Dart）
- 评估对现有 API 的影响

### 2. 修改 Dart 层

在 `lib/flutter_qq_ads.dart` 中添加新方法：

```dart
/// 新功能说明
/// [paramName] 参数说明
static Future<ReturnType> newMethod(String paramName) {
  return FlutterQqAdsPlatform.instance.newMethod(paramName);
}
```

### 3. 修改平台接口

在 `lib/flutter_qq_ads_platform_interface.dart` 中添加抽象方法：

```dart
abstract class FlutterQqAdsPlatform {
  Future<ReturnType> newMethod(String paramName);
}
```

### 4. 修改 Method Channel

在 `lib/flutter_qq_ads_method_channel.dart` 中实现：

```dart
@override
Future<ReturnType> newMethod(String paramName) async {
  final result = await _channel.invokeMethod('newMethod', {'paramName': paramName});
  return result;
}
```

### 5. 修改 Android 实现

在 `android/src/main/java/com/zero/flutter_qq_ads/` 中添加实现。

### 6. 修改 iOS 实现

在 `ios/Classes/` 中添加实现。

### 7. 添加测试

在 `test/` 目录中添加单元测试。

## 测试指南

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/flutter_qq_ads_test.dart
```

### 编写测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

void main() {
  test('initAd should return true', () async {
    // 测试代码
  });
}
```

## 版本管理

### 版本号格式

遵循语义化版本 (SemVer): `主版本.次版本.修订号`

- 主版本: 不兼容的 API 变更
- 次版本: 向后兼容的新功能
- 修订号: 向后兼容的问题修复

### 发布流程

1. 更新 `pubspec.yaml` 中的版本号
2. 更新 `CHANGELOG.md`
3. 创建 Git tag
4. 发布到 pub.dev

## 常见任务

### 添加新的广告类型

1. 在 `lib/flutter_qq_ads.dart` 添加新方法
2. 在 Android 和 iOS 平台实现对应方法
3. 添加相应的事件处理
4. 更新文档

### 修改现有 API

1. 确保向后兼容
2. 更新所有调用处
3. 更新文档和示例
4. 添加废弃注释（如果需要）

### 修复 Bug

1. 复现问题
2. 定位问题代码
3. 编写测试用例
4. 修复问题
5. 验证修复

## 资源链接

- [Flutter 官方文档](https://flutter.dev/docs)
- [优量汇开发者平台](https://e.qq.com/)
- [Dart 语言教程](https://dart.dev/guides)
- [pub.dev 发布指南](https://dart.dev/tools/pub/publishing)

## 联系方式

- 问题反馈: [GitHub Issues](https://github.com/FlutterAds/flutter_qq_ads/issues)
- 官方网站: [https://flutterads.top](https://flutterads.top)