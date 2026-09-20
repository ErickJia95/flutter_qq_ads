/// 自渲染广告数据模型
/// 包含广告素材：标题、描述、图片、Logo等
class NativeAdData {
  /// 广告 ID
  final int adId;

  /// 广告标题
  final String title;

  /// 广告描述
  final String desc;

  /// 广告图标 URL
  final String iconUrl;

  /// 广告大图 URL 列表
  final List<String> imgUrls;

  /// 广告 logo URL（可选）
  final String? logoUrl;

  /// 广告来源/广告主名称
  final String? source;

  /// 是否有应用下载（1:有 0:无）
  final int hasApp;

  /// 是否为应用广告
  final bool isAppAd;

  /// 应用包名（如果有下载）
  final String? appPackageName;

  /// 行动按钮文本（如"立即下载"、"查看详情"）
  final String? buttonText;

  /// 广点通logo（需渲染在广告位下方）
  final String? gdtLogoUrl;

  /// 广告评级（1:普 2:良 3:优）
  final String? adRating;

  /// 广告样式类型
  final String patternType;

  /// 广告 eCPM，单位分
  final int ecpm;

  /// 构造函数
  NativeAdData({
    required this.adId,
    required this.title,
    required this.desc,
    required this.iconUrl,
    required this.imgUrls,
    this.logoUrl,
    this.source,
    this.hasApp = 0,
    this.isAppAd = false,
    this.appPackageName,
    this.buttonText,
    this.gdtLogoUrl,
    this.adRating,
    this.patternType = '',
    this.ecpm = 0,
  });

  /// 从 JSON 解析
  factory NativeAdData.fromJson(Map<String, dynamic> json) {
    return NativeAdData(
      adId: json['adId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      imgUrls: (json['imgUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      logoUrl: json['logoUrl'] as String?,
      source: json['source'] as String?,
      hasApp: json['hasApp'] as int? ?? 0,
      isAppAd: json['isAppAd'] as bool? ?? ((json['hasApp'] as int? ?? 0) == 1),
      appPackageName: json['appPackageName'] as String?,
      buttonText: json['buttonText'] as String?,
      gdtLogoUrl: json['gdtLogoUrl'] as String?,
      adRating: json['adRating'] as String?,
      patternType: json['patternType'] as String? ?? '',
      ecpm: json['ecpm'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'adId': adId,
      'title': title,
      'desc': desc,
      'iconUrl': iconUrl,
      'imgUrls': imgUrls,
      'logoUrl': logoUrl,
      'source': source,
      'hasApp': hasApp,
      'isAppAd': isAppAd,
      'appPackageName': appPackageName,
      'buttonText': buttonText,
      'gdtLogoUrl': gdtLogoUrl,
      'adRating': adRating,
      'patternType': patternType,
      'ecpm': ecpm,
    };
  }

  @override
  String toString() {
    return 'NativeAdData(adId: $adId, title: $title, desc: $desc)';
  }
}
