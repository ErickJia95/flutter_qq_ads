# 自渲染广告调用说明

本文说明 `flutter_qq_ads` 中“自渲染图文广告”的调用方式。

当前能力特点：

- 支持 Android / iOS
- 保留原有模板信息流 `loadFeedAd + AdFeedWidget` 不变
- 新增自渲染图文广告 `loadNativeAd + AdNativeWidget`
- 首版只支持图文素材，不支持视频自渲染

## 1. 先初始化 SDK

和其它广告类型一样，先初始化优量汇 SDK。

```dart
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

final bool ok = await FlutterQqAds.initAd('你的 appId');
```

建议同时注册事件监听，方便排查加载、曝光、点击和错误。

```dart
FlutterQqAds.onEventListener((event) {
  print('adId: ${event.adId}, action: ${event.action}');
});
```

## 2. 拉取自渲染广告数据

通过 `loadNativeAd` 拉取广告。

```dart
final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd(
  '你的广告位ID',
  width: 375,
  height: 0,
  count: 3,
);
```

参数说明：

- `posId`: 自渲染广告位 ID
- `width`: 请求广告时的参考宽度
- `height`: 请求广告时的参考高度，`0` 表示自适应
- `count`: 期望拉取数量，建议 `1~3`

返回值是 `List<NativeAdData>`。

常用字段包括：

- `adId`: 广告唯一标识，后续展示和清理都依赖它
- `title`: 标题
- `desc`: 描述
- `iconUrl`: 图标
- `imgUrls`: 图片列表
- `buttonText`: 按钮文案
- `patternType`: 素材样式
- `ecpm`: eCPM
- `isAppAd`: 是否为应用广告

## 3. 展示自渲染广告

当前版本推荐的展示方式是：

1. 先用 `loadNativeAd` 拉数据
2. 再用返回的 `adId` 渲染 `AdNativeWidget`

最小示例：

```dart
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  final List<NativeAdData> _ads = <NativeAdData>[];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd(
      '你的广告位ID',
      count: 1,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _ads
        ..clear()
        ..addAll(ads);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    final NativeAdData ad = _ads.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(ad.title),
        const SizedBox(height: 8),
        AdNativeWidget(
          adId: ad.adId,
          width: MediaQuery.of(context).size.width,
          height: 220,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _clearAds();
    super.dispose();
  }

  Future<void> _clearAds() async {
    if (_ads.isEmpty) {
      return;
    }
    await FlutterQqAds.clearNativeAd(
      _ads.map((NativeAdData e) => e.adId).toList(),
    );
  }
}
```

## 4. 为什么既要 `loadNativeAd`，又要 `AdNativeWidget`

这是当前版本的设计方式：

- `loadNativeAd` 用来拉取素材数据，并生成广告缓存
- `AdNativeWidget` 用来真正上屏广告
- 曝光、点击、图片绑定等逻辑仍由原生 SDK 处理

因此：

- 不要只拿到 `NativeAdData` 就自己完全用普通 Flutter Widget 渲染并当成广告展示
- 当前推荐的正式展示方式仍然是 `AdNativeWidget(adId: ...)`

## 5. 清理广告

广告不再使用时，调用 `clearNativeAd` 清理缓存对象。

```dart
await FlutterQqAds.clearNativeAd(<int>[adId1, adId2]);
```

建议在页面 `dispose` 中调用。

如果不清理，可能会导致原生广告对象继续占用内存。

## 6. 事件说明

自渲染广告继续走统一事件通道：

```dart
FlutterQqAds.onEventListener((event) {
  print('adId: ${event.adId}, action: ${event.action}');
});
```

常见事件包括：

- `onAdLoaded`
- `onAdExposure`
- `onAdClicked`
- `onAdClosed`
- `onAdError`

如果是错误事件，可继续判断：

```dart
if (event is AdErrorEvent) {
  print('errCode: ${event.errCode}, errMsg: ${event.errMsg}');
}
```

## 7. 与模板信息流的区别

模板信息流：

```dart
final List<int> adIds = await FlutterQqAds.loadFeedAd('广告位ID');
AdFeedWidget(
  posId: '${adIds.first}',
  width: 375,
  height: 256,
)
```

自渲染图文广告：

```dart
final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd('广告位ID');
AdNativeWidget(
  adId: ads.first.adId,
  width: 375,
  height: 220,
)
```

区别总结：

- `loadFeedAd` 返回 `List<int>`
- `loadNativeAd` 返回 `List<NativeAdData>`
- `AdFeedWidget` 是模板信息流
- `AdNativeWidget` 是自渲染图文广告

## 8. 当前限制

- 首版只支持图文自渲染，不支持视频自渲染
- Flutter 侧虽然能拿到素材字段，但正式展示仍建议交给 `AdNativeWidget`
- `AdNativeWidget` 依赖 `adId` 对应的原生缓存，如果缓存已被清理，广告将无法正常展示

## 9. 排查建议

如果广告不展示，优先检查：

1. 是否已先成功调用 `FlutterQqAds.initAd`
2. 自渲染广告位 ID 是否正确
3. 是否先执行了 `loadNativeAd`
4. `AdNativeWidget` 使用的 `adId` 是否来自本次返回的 `NativeAdData`
5. 是否过早调用了 `clearNativeAd`
6. 事件监听里是否收到了 `onAdError`

## 10. 参考

- README 中的自渲染章节：[README.md](/Users/erick/work/flutter_shici/packages/flutter_qq_ads/README.md)
- 示例页面：[native_page.dart](/Users/erick/work/flutter_shici/packages/flutter_qq_ads/example/lib/pages/native_page.dart)
