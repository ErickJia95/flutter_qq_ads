package com.zero.flutter_qq_ads.load;

import android.app.Activity;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.qq.e.ads.nativ.NativeADUnifiedListener;
import com.qq.e.ads.nativ.NativeUnifiedAD;
import com.qq.e.ads.nativ.NativeUnifiedADData;
import com.qq.e.comm.constants.AdPatternType;
import com.qq.e.comm.util.AdError;
import com.zero.flutter_qq_ads.event.AdEventAction;
import com.zero.flutter_qq_ads.page.BaseAdPage;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Locale;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * 自渲染信息流加载对象
 */
public class NativeAdLoad extends BaseAdPage implements NativeADUnifiedListener {
    private final String TAG = NativeAdLoad.class.getSimpleName();
    private MethodChannel.Result result;
    private NativeUnifiedAD nativeAd;

    public void loadNativeAdList(Activity activity, @NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        this.result = result;
        showAd(activity, call);
    }

    @Override
    public void loadAd(@NonNull MethodCall call) {
        int count = call.argument("count");
        nativeAd = new NativeUnifiedAD(activity, this.posId, this);
        nativeAd.loadData(count);
    }

    @Override
    public void onADLoaded(List<NativeUnifiedADData> list) {
        Log.i(TAG, "onADLoaded");
        final List<Map<String, Object>> adResultList = new ArrayList<Map<String, Object>>();
        if (list == null || list.isEmpty()) {
            result.success(adResultList);
            return;
        }
        for (NativeUnifiedADData adItem : list) {
            if (adItem == null || !adItem.isValid()) {
                continue;
            }
            if (adItem.getAdPatternType() == AdPatternType.NATIVE_VIDEO) {
                continue;
            }
            final int key = adItem.hashCode();
            NativeAdManager.getInstance().putAd(key, adItem);
            adResultList.add(toNativeMap(key, adItem));
        }
        sendEvent(AdEventAction.onAdLoaded);
        result.success(adResultList);
    }

    private Map<String, Object> toNativeMap(int key, NativeUnifiedADData adItem) {
        final Map<String, Object> adMap = new HashMap<String, Object>();
        adMap.put("adId", key);
        adMap.put("title", safeText(adItem.getTitle()));
        adMap.put("desc", safeText(adItem.getDesc()));
        adMap.put("iconUrl", safeText(adItem.getIconUrl()));
        adMap.put("imgUrls", buildImageUrls(adItem));
        adMap.put("buttonText", safeText(adItem.getButtonText()));
        adMap.put("source", "");
        adMap.put("patternType", patternTypeToString(adItem.getAdPatternType()));
        adMap.put("ecpm", adItem.getECPM());
        adMap.put("isAppAd", adItem.isAppAd());
        adMap.put("hasApp", adItem.isAppAd() ? 1 : 0);
        return adMap;
    }

    private List<String> buildImageUrls(NativeUnifiedADData adItem) {
        final List<String> result = new ArrayList<String>();
        if (!TextUtils.isEmpty(adItem.getImgUrl())) {
            result.add(adItem.getImgUrl());
        }
        if (adItem.getImgList() != null) {
            result.addAll(adItem.getImgList());
        }
        return result;
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }

    private String patternTypeToString(int patternType) {
        if (patternType == AdPatternType.NATIVE_1IMAGE_2TEXT) {
            return "NATIVE_1IMAGE_2TEXT";
        }
        if (patternType == AdPatternType.NATIVE_2IMAGE_2TEXT) {
            return "NATIVE_2IMAGE_2TEXT";
        }
        if (patternType == AdPatternType.NATIVE_3IMAGE) {
            return "NATIVE_3IMAGE";
        }
        if (patternType == AdPatternType.NATIVE_VIDEO) {
            return "NATIVE_VIDEO";
        }
        return String.valueOf(patternType);
    }

    @Override
    public void onNoAD(AdError error) {
        final String msg = String.format(Locale.getDefault(), "onError, error code: %d, error msg: %s",
                error.getErrorCode(), error.getErrorMsg());
        Log.i(TAG, msg);
        sendErrorEvent(error.getErrorCode(), error.getErrorMsg());
        result.success(new ArrayList<Map<String, Object>>());
    }
}
