import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/native_ad_style.dart';

/// 自渲染图文广告组件
class AdNativeWidget extends StatelessWidget {
  /// [adId] 为 `loadNativeAd` 返回的广告唯一标识
  const AdNativeWidget({
    super.key,
    required this.adId,
    this.show = true,
    this.width = 375,
    this.height = 180,
    this.styleType = NativeAdStyle.verticalListNative,
    this.isOnlyTitle = false,
    this.descMaxLines,
    this.titleWidth,
    this.descWidth,
    this.imageWidth,
    this.imageHeight,
    this.imageRadius,
  });

  /// 广告缓存 id
  final int adId;

  /// 是否显示广告
  final bool show;

  /// 组件宽度
  final double width;

  /// 组件高度
  final double height;

  /// 原生侧渲染样式。
  final NativeAdStyle styleType;

  /// 是否只展示标题区域。
  final bool isOnlyTitle;

  /// 描述文案最大行数。未传时由原生样式自行决定。
  final int? descMaxLines;

  /// 标题文案宽度。未传时由原生样式自行决定。
  final double? titleWidth;

  /// 描述文案宽度。未传时由原生样式自行决定。
  final double? descWidth;

  /// 主图宽度。未传时由原生样式自行决定。
  final double? imageWidth;

  /// 主图高度。未传时由原生样式自行决定。
  final double? imageHeight;

  /// 主图圆角。未传时由原生样式自行决定。
  final double? imageRadius;

  /// 原生视图创建参数。
  ///
  /// 返回值用于创建 AndroidView / UiKitView，并用于测试参数是否完整透传。
  @visibleForTesting
  Map<String, dynamic> get debugCreationParams {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'posId': '$adId',
      'width': width,
      'height': height,
      'styleType': styleType.value,
      'isOnlyTitle': isOnlyTitle,
    };
    if (descMaxLines != null) {
      creationParams['descMaxLines'] = descMaxLines;
    }
    if (titleWidth != null && titleWidth! > 0) {
      creationParams['titleWidth'] = titleWidth;
    }
    if (descWidth != null && descWidth! > 0) {
      creationParams['descWidth'] = descWidth;
    }
    if (imageWidth != null && imageWidth! > 0) {
      creationParams['imageWidth'] = imageWidth;
    }
    if (imageHeight != null && imageHeight! > 0) {
      creationParams['imageHeight'] = imageHeight;
    }
    if (imageRadius != null && imageRadius! > 0) {
      creationParams['imageRadius'] = imageRadius;
    }
    return creationParams;
  }

  /// 原生 PlatformView 的稳定 key。
  ///
  /// 返回值覆盖全部影响原生布局的参数，参数变化时强制重建原生视图。
  @visibleForTesting
  Key get debugPlatformViewKey {
    return ValueKey<String>(
      <Object?>[
        adId,
        show,
        width,
        height,
        styleType.value,
        isOnlyTitle,
        descMaxLines,
        titleWidth,
        descWidth,
        imageWidth,
        imageHeight,
        imageRadius,
      ].join('|'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!show || width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }

    const String viewType = 'flutter_qq_ads_native';
    final Map<String, dynamic> creationParams = debugCreationParams;

    final Widget view;
    if (Platform.isIOS) {
      view = UiKitView(
        key: debugPlatformViewKey,
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      view = AndroidView(
        key: debugPlatformViewKey,
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: view,
    );
  }
}
