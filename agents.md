# `flutter_qq_ads` 代理协作指南

本文档适用于本仓库的 AI 代理、自动化工具和协作者。开始任务前先阅读本文件；如果某个子目录存在更具体的 `AGENTS.md`，以更具体的规则为准。

## 0. 项目级强制规则

- **先保护用户改动**：开始前运行 `git status --short`，确认当前分支和任务范围。工作区已有改动默认属于用户，不得覆盖、回退、暂存、提交或顺手修复。
- **最小修改范围**：只改完成当前任务所需的文件；不要无关重构、批量格式化、改名或升级普通依赖。
- **平台 SDK 必须保持最新**：Android 和 iOS 使用的腾讯优量汇官方 SDK 必须跟随官方最新稳定版。任何涉及平台实现、依赖、发布或兼容性修复的任务，都必须先核对官方文档和官方依赖源的当前版本，不得仅依据本地缓存、旧锁文件或历史代码判断版本是否最新。
  - Android 依赖位置：`android/build.gradle` 的 `com.qq.e.union:union`。
  - iOS 依赖位置：`ios/flutter_qq_ads.podspec` 的 `GDTMobSDK`；示例工程的 `example/ios/Podfile.lock` 是生成结果，不能作为版本来源。
  - 官方参考：[优量汇 Android SDK](https://developers.qq.com/doc/oplatform/Mobile_SDK/Android_SDK.html)、[优量汇 iOS SDK](https://developers.qq.com/doc/oplatform/Mobile_SDK/iOS_SDK.html)、[Android Maven 版本](https://central.sonatype.com/artifact/com.qq.e.union/union/versions)、[CocoaPods GDTMobSDK](https://cocoapods.org/pods/GDTMobSDK)。
  - 若最新 SDK 引入 API、最低系统版本或构建工具变化，必须同步调整原生代码、文档和示例，并分别验证 Android 与 iOS；不能为了保留旧实现而继续使用过期 SDK。
  - SDK 升级交付时必须说明核对日期、旧版本、新版本、兼容性影响和锁文件变化。除非用户明确要求，不要把 SDK 降级回旧版本。
- **原生集成是高风险区域**：修改 `android/`、`ios/`、Gradle、Podspec、Manifest、Info.plist 或平台通道后，必须至少完成对应平台构建检查，并检查另一平台没有被共享 Dart/API 改动破坏。
- **生成文件不手改**：`example/ios/Podfile.lock` 等依赖锁文件通过 CocoaPods/Flutter 命令生成；不要手工编辑生成内容。
- **不擅自操作 Git**：除非用户明确要求，不切换分支、不提交、不推送、不合并、不改写历史。

## 1. 项目概览

`flutter_qq_ads` 是一个 Flutter 插件，用于集成腾讯优量汇（广点通）广告，支持 Android 和 iOS。插件通过 MethodChannel 传递调用，通过 EventChannel 回传广告事件，并提供原生广告视图。

技术栈：

- Dart / Flutter（最低 Flutter `2.5.0`，Dart `>=2.17.0 <4.0.0`，以 `pubspec.yaml` 为准）
- Android Java、Gradle、腾讯优量汇 Android SDK
- iOS Objective-C、CocoaPods、`GDTMobSDK`

## 2. 目录与职责

| 目录/文件 | 职责 |
|---|---|
| `lib/flutter_qq_ads.dart` | 对外公开 API |
| `lib/flutter_qq_ads_platform_interface.dart` | 平台接口和契约 |
| `lib/flutter_qq_ads_method_channel.dart` | Dart MethodChannel 实现 |
| `lib/event/` | 广告事件、错误事件、激励事件和事件处理 |
| `lib/view/` | Banner、Feed、Native 广告 Flutter 组件 |
| `lib/model/` | Native 广告数据和样式模型 |
| `android/src/main/java/com/zero/flutter_qq_ads/` | Android 插件、广告加载器、页面和原生视图 |
| `android/build.gradle` | Android 构建配置和优量汇 Maven 依赖 |
| `ios/Classes/` | iOS 插件、广告加载器、页面和原生视图 |
| `ios/flutter_qq_ads.podspec` | iOS Pod 依赖、最低系统版本和插件元数据 |
| `example/` | 可运行示例及 Android/iOS 集成验证入口 |
| `test/` | Dart 单元测试和 MethodChannel mock |
| `README.md`、`use.md` | 使用说明和 API 示例 |

## 3. API 与跨平台修改流程

新增或修改公开能力时，按以下顺序检查，保持 Dart、Android、iOS 三端契约一致：

1. 在 `lib/flutter_qq_ads.dart` 定义或调整公开 API，并补充 `///` 文档注释。
2. 在 `lib/flutter_qq_ads_platform_interface.dart` 更新平台接口。
3. 在 `lib/flutter_qq_ads_method_channel.dart` 实现方法名、参数键和返回值转换。
4. 在 Android `FlutterQqAdsPlugin` / `PluginDelegate` 及对应 `load/`、`page/` 类中实现。
5. 在 iOS `FlutterQqAdsPlugin` 及对应 `Load/`、`Page/` 类中实现。
6. 更新事件动作、错误/奖励回调或原生视图注册（如功能涉及）。
7. 更新 `test/`、`example/`、`README.md` 或 `use.md`，并验证两端行为一致。

MethodChannel 约定：

- 方法名和参数键必须在三端完全一致。
- 跨平台返回值应使用可序列化的基础类型、列表或 Map；在 Dart 边界尽快转换成强类型模型。
- 原生异常和广告错误要转换为已有事件/错误模型，不要静默吞掉错误。
- 广告对象、View、监听器和缓存列表在关闭/清除时必须释放，避免重复监听和内存泄漏。

## 4. Android 约定

- Java 遵循 Google Java 风格：4 空格缩进、PascalCase 类名、camelCase 方法名和变量名。
- 优量汇初始化、广告生命周期、Activity/Context 使用必须与当前官方 Android SDK 文档一致。
- 修改 `com.qq.e.union:union` 版本时，检查 SDK API 变更、`minSdkVersion`、`compileSdk`、Android Gradle Plugin、Gradle wrapper 和 Manifest 要求。
- 优先从 `example/` 执行真实集成构建；不能只依赖 Dart 测试证明 Android 集成有效。
- Android 专属改动至少检查：依赖解析、编译、插件注册、广告加载/销毁和事件回调。

常用检查：

```bash
flutter pub get
cd example && flutter build apk --debug
```

## 5. iOS 约定

- Objective-C 遵循 Apple 命名和内存管理规范；公共头文件与实现保持同步。
- `GDTMobSDK` 必须使用官方最新稳定版本；更新 `ios/flutter_qq_ads.podspec` 后，在示例工程通过 CocoaPods 重新解析依赖，不得手改 `Podfile.lock`。
- 检查最新 SDK 的最低 iOS 版本、Bitcode/架构要求、隐私权限和 IDFA/ATT 配置，并同步更新 README 与示例。
- iOS 专属改动至少检查：Pod 解析、编译、插件注册、广告页面生命周期、原生 View 销毁和事件回调。

常用检查（macOS 且已安装 CocoaPods 时）：

```bash
cd example/ios && pod install --repo-update
cd .. && flutter build ios --debug --no-codesign
```

## 6. 测试与验证

按改动范围选择最小但充分的验证集；涉及平台 SDK 时不能只运行 Dart 测试。

```bash
flutter pub get
flutter analyze
flutter test
```

验证重点：

- MethodChannel 方法名、参数和返回类型与 mock/原生实现一致。
- Banner、插屏、开屏、激励视频、Feed 和 Native 广告的成功、失败、关闭、奖励事件均有覆盖或人工验证。
- SDK 升级后同时验证 Android 和 iOS；至少在 `example/` 完成对应平台 debug 构建。
- 文档中的版本号、最低系统要求、配置字段和实际代码保持一致。

## 7. 版本与发布

1. SDK 或公开 API 变更前，先检查官方最新稳定版和兼容性说明。
2. 更新 `android/build.gradle`、`ios/flutter_qq_ads.podspec` 及必要的示例锁文件/构建配置。
3. 更新 `CHANGELOG.md`、README 或 `use.md`，明确破坏性变化和平台要求。
4. 运行 Dart 检查及两端构建验证。
5. 发布前确认 `pubspec.yaml`、Podspec 版本和文档版本一致；不要遗漏示例工程验证。

## 8. 交付说明

完成任务时简要说明：

- 修改了哪些文件以及原因；
- Android/iOS SDK 是否核对为最新稳定版，核对日期和版本号；
- 执行了哪些测试、分析和平台构建；
- 是否存在未验证的平台限制、外部 SDK 风险或待用户决定事项；
- 工作区中哪些已有改动被保留且未触碰。

