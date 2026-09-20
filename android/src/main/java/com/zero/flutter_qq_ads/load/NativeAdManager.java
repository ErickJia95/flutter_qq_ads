package com.zero.flutter_qq_ads.load;

import com.qq.e.ads.nativ.NativeUnifiedADData;

import java.util.HashMap;
import java.util.Map;

/**
 * 自渲染广告管理
 */
public class NativeAdManager {
    private static NativeAdManager instance;

    public static synchronized NativeAdManager getInstance() {
        if (instance == null) {
            instance = new NativeAdManager();
        }
        return instance;
    }

    private final Map<Integer, NativeUnifiedADData> nativeAdList = new HashMap<Integer, NativeUnifiedADData>();

    public void putAd(int key, NativeUnifiedADData ad) {
        nativeAdList.put(key, ad);
    }

    public NativeUnifiedADData getAd(int key) {
        return nativeAdList.get(key);
    }

    public NativeUnifiedADData removeAd(int key) {
        return nativeAdList.remove(key);
    }
}
