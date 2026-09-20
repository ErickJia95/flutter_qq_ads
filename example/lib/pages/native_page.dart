import 'package:flutter/material.dart';
import 'package:flutter_qq_ads/flutter_qq_ads.dart';

import '../ads_config.dart';
import '../widgets/widgets.dart';

/// 自渲染图文广告页面
class NativePage extends StatefulWidget {
  const NativePage({Key? key}) : super(key: key);

  @override
  State<NativePage> createState() => _NativePageState();
}

class _NativePageState extends State<NativePage> {
  final List<NativeAdData> _nativeAds = <NativeAdData>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _clearAds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, '自渲染图文广告'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _nativeAds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final NativeAdData ad = _nativeAds[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ad.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: AdNativeWidget(
                        adId: ad.adId,
                        width: MediaQuery.of(context).size.width - 24,
                        height: 220,
                        styleType: NativeAdStyle.verticalListNative,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _loadAds() async {
    final List<NativeAdData> ads = await FlutterQqAds.loadNativeAd(
      AdsConfig.feedId,
      count: 3,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _nativeAds
        ..clear()
        ..addAll(ads);
      _loading = false;
    });
  }

  Future<void> _clearAds() async {
    if (_nativeAds.isEmpty) {
      return;
    }
    await FlutterQqAds.clearNativeAd(
      _nativeAds.map((NativeAdData ad) => ad.adId).toList(),
    );
  }
}
