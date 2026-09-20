import 'ad_event.dart';

/// 广告错误事件
class AdErrorEvent extends AdEvent {
  AdErrorEvent(
      {required this.errCode,
      required this.errMsg,
      required super.adId,
      required super.action});
  // 错误码
  final int errCode;
  // 错误信息
  final String errMsg;
  // 解析 json 为错误事件对象
  factory AdErrorEvent.fromJson(Map<dynamic, dynamic> json) {
    return AdErrorEvent(
      errCode: json['errCode'],
      errMsg: json['errMsg'],
      adId: json['adId'],
      action: json['action'],
    );
  }
}
