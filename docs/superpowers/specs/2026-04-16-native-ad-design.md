# flutter_qq_ads 自渲染图文广告设计

## 背景

当前插件已经支持模板信息流广告，调用方式为 `loadFeedAd + AdFeedWidget`。仓库中也已经存在 `NativeAdData`、`loadNativeAd()`、`clearNativeAd()` 的接口雏形，但 Dart MethodChannel、Android、iOS 和示例都还未真正打通，因此当前版本实际上不支持优量汇“开发者自渲染”能力。

这次需求是在不破坏现有模板信息流调用的前提下，新增一套 Android + iOS 自渲染广告能力，并优先支持图文素材，不在首版覆盖视频自渲染。

## 目标

- 保留现有模板信息流 API 和行为不变。
- 新增一套自渲染图文广告能力，覆盖 Android 和 iOS。
- 让 Flutter 层既能拿到广告素材数据，也能用一个新的 Widget 完成稳定展示。
- 保证曝光、点击、关闭、下载状态等关键事件仍通过原生 SDK 正常上报。

## 非目标

- 不替换或统一现有 `loadFeedAd + AdFeedWidget`。
- 不在首版支持自渲染视频广告及其播放控制。
- 不尝试把任意 Flutter Widget 直接映射成原生 SDK 的点击视图集合。
- 不重构现有全局事件通道模型。

## 选型结论

采用方案 C：新增“素材数据 API + 原生容器 Widget”的混合模式。

设计原因：

- 仓库已经存在 `NativeAdData` 和相关 API 雏形，补齐这一层最自然。
- 仅返回素材数据并不足以可靠完成曝光、点击、图片绑定和下载行为绑定。
- 新增 `AdNativeWidget` 后，真正的广告展示、点击区注册和 SDK 绑定仍由原生侧负责，首版风险最低。
- 未来如果要继续增强 Flutter 自定义能力，不需要推翻这次的 API 方向。

## 对外 API 设计

### 保持不变

- `FlutterQqAds.loadFeedAd(...)`
- `FlutterQqAds.clearFeedAd(...)`
- `AdFeedWidget`

### 新增和补齐

- `FlutterQqAds.loadNativeAd(String posId, {int width = 375, int height = 0, int count = 1})`
  - 返回 `List<NativeAdData>`
  - `width` / `height` 继续保留，用于原生请求素材尺寸与卡片布局估算
- `FlutterQqAds.clearNativeAd(List<int> list)`
  - 清理原生缓存的自渲染广告对象
- `AdNativeWidget`
  - 必填：`adId`
  - 可选：`show`、`width`、`height`
  - 行为模式与 `AdFeedWidget` 接近，便于迁移和理解

### NativeAdData 字段

首版保留或补强以下字段，满足图文自渲染所需：

- `adId`
- `title`
- `desc`
- `iconUrl`
- `imgUrls`
- `buttonText`
- `source`
- `isAppAd` 或兼容现有 `hasApp`
- `patternType`
- `ecpm`

可保留当前模型里的兼容字段，但首版文档和示例只承诺以上图文字段。

## Flutter 层设计

### 数据与渲染职责

- `loadNativeAd()` 负责请求素材并建立 `adId -> 原生广告对象` 的映射。
- `NativeAdData` 负责把核心广告素材暴露给 Flutter。
- `AdNativeWidget` 负责真正上屏广告，并通过 PlatformView 承载原生广告容器。

### 使用模式

推荐使用方式：

1. 调用 `loadNativeAd()` 获取 `NativeAdData` 列表。
2. Flutter 侧用 `NativeAdData` 决定列表插入位置、占位尺寸、标题摘要等外围布局。
3. 需要真正展示广告时，渲染 `AdNativeWidget(adId: data.adId, ...)`。

这样可以让 Flutter 保持对列表编排的控制，同时把曝光点击绑定继续交给原生 SDK。

## Android 设计

### 加载层

- 新增自渲染广告加载对象，使用优量汇 Android 自渲染入口：
  - `NativeUnifiedAD`
  - `NativeUnifiedADData`
- 在 `onADLoaded(List<NativeUnifiedADData>)` 中：
  - 过滤无效广告
  - 过滤视频样式广告
  - 提取图文字段构造成可序列化 Map
  - 生成 `adId` 并缓存 `NativeUnifiedADData`
  - 返回 Dart 层 `List<Map<String, dynamic>>`

### 缓存管理

- 新增 `NativeAdManager`
- 维护 `adId -> NativeUnifiedADData`
- `clearNativeAd()` 和 `dispose` 时负责销毁广告对象并移除缓存

### PlatformView 展示层

- 新增 `AdNativeWidget` 对应的 Android `PlatformView`
- 使用 `NativeAdContainer` 作为广告根容器
- 在容器内布置原生文本、图片、按钮等子视图
- 通过 SDK 提供的方法完成绑定：
  - `bindAdToView(...)`
  - `bindImageViews(...)`
- 点击按钮、图片、整体卡片等元素由原生侧统一注册为可点击区域

### 事件

- 复用现有插件事件通道
- 首版至少覆盖：
  - loaded
  - exposure
  - clicked
  - closed
  - error
  - status changed

### 图文样式处理

根据 `getAdPatternType()` 区分：

- 单图双文
- 双图双文
- 三小图

首版仅对图文样式进行视图布局和图片绑定。若拿到视频样式，则在加载阶段跳过，避免 Dart 收到无法展示的素材。

## iOS 设计

### 加载层

- 新增 iOS 自渲染广告加载对象
- 使用优量汇 iOS 自渲染对应的广告加载类和广告数据对象
- 成功回调中：
  - 过滤无效广告
  - 过滤视频样式广告
  - 提取素材字段
  - 生成并缓存 `adId`
  - 返回 `List<Map<String, dynamic>>`

### 缓存管理

- 新增 iOS NativeAd 管理器
- 维护 `adId -> 原生广告对象`
- 在 `clearNativeAd()` 或 PlatformView 销毁时清理缓存和观察者

### PlatformView 展示层

- 新增 `FlutterPlatformView` 实现，对应 `AdNativeWidget`
- 根视图使用 SDK 要求的广告容器
- 使用原生 `UILabel`、`UIImageView`、`UIButton` 等组件构造图文卡片
- 通过 SDK 提供的广告绑定接口完成：
  - 广告容器绑定
  - 点击视图绑定
  - 图片视图绑定

### 事件

- 继续通过插件现有事件通道回传
- 保证图文广告的曝光、点击、错误、关闭和下载状态类事件可用

## 向后兼容策略

- 不修改现有模板信息流方法签名与调用约定。
- 不复用 `FeedAdManager`，为自渲染新增独立管理器，避免对象类型混用。
- 不更改现有 `AdFeedWidget` 的 viewType 和 MethodChannel 名称。
- 新增能力全部走独立的 method 名称、缓存管理和 PlatformView 类型。

## 错误处理

- 原生请求失败时：
  - 通过事件通道发送错误事件
  - MethodChannel 返回空列表，而不是抛出导致 Flutter 崩溃
- 广告数据无效、样式不支持时：
  - 直接过滤，不返回给 Flutter
- `AdNativeWidget` 找不到缓存广告时：
  - 展示空白容器
  - 发送错误事件，便于定位 adId 生命周期问题

## 示例与文档更新

- 新增一个独立的自渲染广告示例页，不替换现有 feed 示例。
- README 增加“自渲染广告”章节，说明：
  - 与模板信息流的区别
  - 首版仅支持图文
  - 推荐用法：`loadNativeAd + AdNativeWidget`

## 测试与验证

至少执行：

- `flutter analyze`
- `flutter test`

如果本地原生环境可用，补充人工验证：

- Android 示例页可成功拉取并展示图文自渲染广告
- iOS 示例页可成功拉取并展示图文自渲染广告
- 点击广告可正常跳转
- 曝光和点击事件能回传
- 页面销毁后 `clearNativeAd()` 不报错且不会重复持有对象
- 现有模板信息流示例保持可用

## 风险与约束

- iOS 自渲染接口命名与 Android 不完全一致，实现时必须以当前优量汇 iOS SDK 实际 API 为准。
- 广告素材样式受后台广告位配置影响，测试环境可能无法稳定拿到三种图文样式。
- 如果 Flutter 侧希望深度定制布局，首版 `AdNativeWidget` 的可配置项可能不够，需要后续再扩展。

## 实施顺序

1. 补齐 Dart platform interface 与 method channel
2. 实现 Android 自渲染加载、缓存和 PlatformView
3. 实现 iOS 自渲染加载、缓存和 PlatformView
4. 新增 `AdNativeWidget`
5. 更新 example 和 README
6. 跑分析、测试和可执行的手工验证
