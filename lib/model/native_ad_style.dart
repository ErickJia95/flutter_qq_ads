/// 自渲染广告原生布局样式。
enum NativeAdStyle {
  /// 竖向封面式广告：上方展示广告图片，下方展示标题与描述。
  verticalListNative('verticalListNative'),

  /// 横向封面式广告：左侧展示图片，右侧上方标题、下方描述。
  horizontalListNative('horizontalListNative'),

  /// 纯图片 Banner 广告：仅展示广告图片，不承载标题与描述区域。
  bannerOnlyImageNative('bannerOnlyImageNative');

  /// 传递给 Android / iOS 原生侧的样式标识。
  final String value;

  const NativeAdStyle(this.value);
}
