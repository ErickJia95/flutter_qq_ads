package com.zero.flutter_qq_ads.page;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Typeface;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.qq.e.ads.nativ.NativeADEventListener;
import com.qq.e.ads.nativ.NativeUnifiedADData;
import com.qq.e.ads.nativ.widget.NativeAdContainer;
import com.qq.e.comm.constants.AdPatternType;
import com.qq.e.comm.util.AdError;
import com.zero.flutter_qq_ads.PluginDelegate;
import com.zero.flutter_qq_ads.event.AdEventAction;
import com.zero.flutter_qq_ads.load.NativeAdManager;
import com.zero.flutter_qq_ads.utils.UIUtils;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.platform.PlatformView;

/**
 * 自渲染图文广告 View
 */
class AdNativeView extends BaseAdPage implements PlatformView {
    private static final String STYLE_VERTICAL_LIST_NATIVE = "verticalListNative";
    private static final String STYLE_HORIZONTAL_LIST_NATIVE = "horizontalListNative";
    private static final String STYLE_BANNER_ONLY_IMAGE_NATIVE = "bannerNative";

    @NonNull
    private final NativeAdContainer container;
    private final Context context;
    private final String styleType;
    private final boolean isOnlyTitle;
    private final Integer descMaxLines;
    private final Integer viewWidthPx;
    private final Integer viewHeightPx;
    private final Integer titleWidthPx;
    private final Integer descWidthPx;
    private final Integer imageWidthPx;
    private final Integer imageHeightPx;
    private final Integer imageRadiusPx;
    private NativeUnifiedADData nativeAdData;
    private ImageView iconView;
    private final List<ImageView> mediaViews = new ArrayList<ImageView>();
    private TextView titleView;
    private TextView descView;
    private TextView sourceView;
    private Button actionButton;

    AdNativeView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams) {
        this.context = context;
        this.container = new NativeAdContainer(context);
        this.container.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        ));
        this.container.setBackgroundColor(Color.TRANSPARENT);
        final Object rawStyleType = creationParams == null ? null : creationParams.get("styleType");
        this.styleType = resolveStyleType(rawStyleType);
        this.isOnlyTitle = parseBoolean(creationParams == null ? null : creationParams.get("isOnlyTitle"));
        this.descMaxLines = parseDescMaxLines(creationParams == null ? null : creationParams.get("descMaxLines"));
        this.viewWidthPx = parseDimensionPx(creationParams == null ? null : creationParams.get("width"));
        this.viewHeightPx = parseDimensionPx(creationParams == null ? null : creationParams.get("height"));
        this.titleWidthPx = parseDimensionPx(creationParams == null ? null : creationParams.get("titleWidth"));
        this.descWidthPx = parseDimensionPx(creationParams == null ? null : creationParams.get("descWidth"));
        this.imageWidthPx = parseDimensionPx(creationParams == null ? null : creationParams.get("imageWidth"));
        this.imageHeightPx = parseDimensionPx(creationParams == null ? null : creationParams.get("imageHeight"));
        this.imageRadiusPx = parseDimensionPx(creationParams == null ? null : creationParams.get("imageRadius"));
        this.container.setClipChildren(true);
        this.container.setClipToPadding(false);
        this.container.setLayoutParams(new FrameLayout.LayoutParams(
                resolveViewWidthPx(),
                resolveViewHeightPx()
        ));
        final MethodCall call = new MethodCall("AdNativeView", creationParams);
        showAd(PluginDelegate.getInstance().activity, call);
    }

    @NonNull
    @Override
    public View getView() {
        return container;
    }

    @Override
    public void dispose() {
        container.removeAllViews();
        if (nativeAdData != null) {
            nativeAdData.destroy();
            NativeAdManager.getInstance().removeAd(Integer.parseInt(this.posId));
            nativeAdData = null;
        }
    }

    @Override
    public void loadAd(@NonNull MethodCall call) {
        final int key = Integer.parseInt(this.posId);
        nativeAdData = NativeAdManager.getInstance().getAd(key);
        if (nativeAdData == null || !nativeAdData.isValid()) {
            sendErrorEvent(-101, "native ad not found");
            return;
        }
        buildLayout();
        bindNativeAd();
    }

    private void buildLayout() {
        container.removeAllViews();
        mediaViews.clear();

        if (STYLE_HORIZONTAL_LIST_NATIVE.equals(styleType)) {
            container.addView(buildHorizontalListLayout());
        } else if (STYLE_BANNER_ONLY_IMAGE_NATIVE.equals(styleType)) {
            container.addView(buildBannerOnlyImageLayout());
        } else {
            container.addView(buildVerticalListLayout());
        }

        loadImage(nativeAdData.getIconUrl(), iconView);
    }

    private View buildVerticalListLayout() {
        return buildImageTextDownloadLayout();
    }

    private View buildHorizontalListLayout() {
        return buildWideStripLayout();
    }

    private View buildBannerOnlyImageLayout() {
        final LinearLayout root = createRootLayout(LinearLayout.VERTICAL, 12);
        root.setGravity(Gravity.CENTER | Gravity.TOP);

        final FrameLayout imageFrame = new FrameLayout(context);
        final LinearLayout.LayoutParams imageFrameParams = new LinearLayout.LayoutParams(
                resolveImageWidthPx(),
                resolveBannerImageHeightPx()
        );
        imageFrameParams.gravity = Gravity.CENTER_HORIZONTAL;
        root.addView(imageFrame, imageFrameParams);

        final ImageView mediaView = createMediaViewPx(resolveImageRadiusPx());
        mediaView.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        ));
        imageFrame.addView(mediaView);
        mediaViews.add(mediaView);

        final String primaryImageUrl = getPrimaryImageUrl();
        if (!TextUtils.isEmpty(primaryImageUrl)) {
            loadImage(primaryImageUrl, mediaView);
        }
        return root;
    }

    private View buildWideStripLayout() {
        final LinearLayout root = createRootLayout(LinearLayout.HORIZONTAL, 12);
        root.setGravity(Gravity.CENTER_VERTICAL);

        final FrameLayout imageFrame = new FrameLayout(context);
        final LinearLayout.LayoutParams imageFrameParams = new LinearLayout.LayoutParams(
                resolveImageWidthPx(),
                resolveImageHeightPx()
        );
        imageFrameParams.gravity = Gravity.CENTER_VERTICAL;
        root.addView(imageFrame, imageFrameParams);

        final ImageView mediaView = createMediaViewPx(resolveImageRadiusPx());
        mediaView.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        ));
        imageFrame.addView(mediaView);
        mediaViews.add(mediaView);

        final LinearLayout textArea = new LinearLayout(context);
        textArea.setOrientation(LinearLayout.VERTICAL);
        textArea.setGravity(isOnlyTitle ? (Gravity.CENTER_VERTICAL | Gravity.START) : (Gravity.TOP | Gravity.START));
        final LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
        );
        textParams.leftMargin = UIUtils.dp2px(context, 12);
        textArea.setLayoutParams(textParams);

        titleView = createTitleView(16, 1);
        applyFixedWidth(titleView, titleWidthPx);
        titleView.setText(nativeAdData.getTitle());
        final LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
            titleView.setLayoutParams(titleParams);
        textArea.addView(titleView);

        if (!isOnlyTitle) {
            descView = createDescView(12, resolveDescMaxLines(2));
            applyFixedWidth(descView, descWidthPx);
            descView.setText(nativeAdData.getDesc());
            final LinearLayout.LayoutParams descParams = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
            );
            descParams.topMargin = UIUtils.dp2px(context, 6);
            descView.setLayoutParams(descParams);
            textArea.addView(descView);
        } else {
            descView = null;
        }

        root.addView(textArea);

        final String primaryImageUrl = getPrimaryImageUrl();
        if (!TextUtils.isEmpty(primaryImageUrl)) {
            loadImage(primaryImageUrl, mediaView);
        }
        return root;
    }

    private View buildImageTextDownloadLayout() {
        final LinearLayout root = createRootLayout(LinearLayout.VERTICAL, 12);
        root.setGravity(Gravity.TOP | Gravity.CENTER_HORIZONTAL);

        final FrameLayout mediaFrame = new FrameLayout(context);
        final LinearLayout.LayoutParams mediaFrameParams = new LinearLayout.LayoutParams(
                resolveImageWidthPx(),
                resolveImageHeightPx()
        );
        mediaFrameParams.gravity = Gravity.CENTER_HORIZONTAL;
        root.addView(mediaFrame, mediaFrameParams);

        final ImageView mediaView = createMediaViewPx(resolveImageRadiusPx());
        mediaView.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        ));
        mediaFrame.addView(mediaView);
        mediaViews.add(mediaView);

        final LinearLayout contentWrap = new LinearLayout(context);
        contentWrap.setOrientation(LinearLayout.HORIZONTAL);
        contentWrap.setGravity(Gravity.CENTER_VERTICAL);
        final LinearLayout.LayoutParams contentParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
        );
        contentParams.topMargin = UIUtils.dp2px(context, 12);
        contentWrap.setLayoutParams(contentParams);

        final LinearLayout textWrap = new LinearLayout(context);
        textWrap.setOrientation(LinearLayout.VERTICAL);
        textWrap.setGravity(isOnlyTitle ? (Gravity.CENTER_VERTICAL | Gravity.START) : (Gravity.TOP | Gravity.START));
        textWrap.setLayoutParams(new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
        ));

        titleView = createTitleView(16, isOnlyTitle ? 3 : 2);
        applyFixedWidth(titleView, titleWidthPx);
        titleView.setText(nativeAdData.getTitle());
        textWrap.addView(titleView);

        if (!isOnlyTitle) {
            descView = createDescView(12, resolveDescMaxLines(2));
            applyFixedWidth(descView, descWidthPx);
            descView.setText(nativeAdData.getDesc());
            final LinearLayout.LayoutParams descParams =
                    (LinearLayout.LayoutParams) descView.getLayoutParams();
            descParams.topMargin = UIUtils.dp2px(context, 6);
            textWrap.addView(descView);
        } else {
            descView = null;
        }
        contentWrap.addView(textWrap);

        final LinearLayout actionRow = new LinearLayout(context);
        actionRow.setOrientation(LinearLayout.HORIZONTAL);
        actionRow.setGravity(Gravity.END | Gravity.CENTER_VERTICAL);
        final LinearLayout.LayoutParams actionRowParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        actionRowParams.leftMargin = UIUtils.dp2px(context, 12);
        actionRow.setLayoutParams(actionRowParams);

        actionButton = createActionButton(84, 34, true);
        actionRow.addView(actionButton);
        contentWrap.addView(actionRow);

        root.addView(contentWrap);

        final String primaryImageUrl = getPrimaryImageUrl();
        if (!TextUtils.isEmpty(primaryImageUrl)) {
            loadImage(primaryImageUrl, mediaView);
        }
        return root;
    }

    private LinearLayout createRootLayout(int orientation, int paddingDp) {
        final int padding = UIUtils.dp2px(context, paddingDp);
        final LinearLayout root = new LinearLayout(context);
        root.setOrientation(orientation);
        root.setPadding(padding, padding, padding, padding);
        root.setClipChildren(true);
        root.setClipToPadding(false);
        root.setBackgroundColor(Color.parseColor("#FFF8F1"));
        root.setLayoutParams(new FrameLayout.LayoutParams(
                resolveViewWidthPx(),
                resolveViewHeightPx()
        ));
        return root;
    }

    private View buildBadgeRow() {
        final LinearLayout row = new LinearLayout(context);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));

        final TextView badgeView = new TextView(context);
        badgeView.setText("广告");
        badgeView.setTextSize(11);
        badgeView.setTextColor(Color.parseColor("#EE7F26"));
        badgeView.setTypeface(Typeface.DEFAULT_BOLD);
        badgeView.setPadding(
                UIUtils.dp2px(context, 8),
                UIUtils.dp2px(context, 3),
                UIUtils.dp2px(context, 8),
                UIUtils.dp2px(context, 3)
        );
        badgeView.setBackground(createRoundedDrawable("#FFF0DF", 999));
        row.addView(badgeView);

        sourceView = createSourceView();
        final LinearLayout.LayoutParams sourceParams =
                new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT);
        sourceParams.leftMargin = UIUtils.dp2px(context, 8);
        sourceView.setLayoutParams(sourceParams);
        row.addView(sourceView);
        return row;
    }

    private View buildHeader(boolean showIcon, boolean compactText) {
        final LinearLayout header = new LinearLayout(context);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        final LinearLayout.LayoutParams headerParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        headerParams.topMargin = UIUtils.dp2px(context, 10);
        header.setLayoutParams(headerParams);

        if (showIcon) {
            iconView = createMediaView(12);
            final LinearLayout.LayoutParams iconParams =
                    new LinearLayout.LayoutParams(UIUtils.dp2px(context, 44), UIUtils.dp2px(context, 44));
            iconView.setLayoutParams(iconParams);
            header.addView(iconView);
        } else {
            iconView = createMediaView(12);
            iconView.setVisibility(View.GONE);
        }

        final LinearLayout textWrap = new LinearLayout(context);
        textWrap.setOrientation(LinearLayout.VERTICAL);
        final LinearLayout.LayoutParams textParams =
                new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        if (showIcon) {
            textParams.leftMargin = UIUtils.dp2px(context, 10);
        }
        textWrap.setLayoutParams(textParams);

        titleView = createTitleView(compactText ? 15 : 17, isOnlyTitle ? 3 : (compactText ? 2 : 1));
        applyFixedWidth(titleView, titleWidthPx);
        titleView.setText(nativeAdData.getTitle());
        textWrap.addView(titleView);

        if (!isOnlyTitle) {
            descView = createDescView(compactText ? 12 : 13, resolveDescMaxLines(compactText ? 2 : 3));
            applyFixedWidth(descView, descWidthPx);
            descView.setText(nativeAdData.getDesc());
            final LinearLayout.LayoutParams descParams = (LinearLayout.LayoutParams) descView.getLayoutParams();
            descParams.topMargin = UIUtils.dp2px(context, 4);
            textWrap.addView(descView);
        } else {
            descView = null;
        }
        header.addView(textWrap);

        actionButton = createActionButton(compactText ? 76 : 84, 34);
        final LinearLayout.LayoutParams actionParams =
                new LinearLayout.LayoutParams(UIUtils.dp2px(context, compactText ? 76 : 84),
                        UIUtils.dp2px(context, 34));
        actionParams.leftMargin = UIUtils.dp2px(context, 10);
        actionButton.setLayoutParams(actionParams);
        header.addView(actionButton);
        return header;
    }

    private TextView createTitleView(int sizeSp, int maxLines) {
        final TextView view = new TextView(context);
        view.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        view.setTextColor(Color.parseColor("#2A2232"));
        view.setTextSize(sizeSp);
        view.setTypeface(Typeface.DEFAULT_BOLD);
        view.setMaxLines(maxLines);
        view.setEllipsize(TextUtils.TruncateAt.END);
        return view;
    }

    private TextView createDescView(int sizeSp, int maxLines) {
        final TextView view = new TextView(context);
        view.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        view.setTextColor(Color.parseColor("#786D87"));
        view.setTextSize(sizeSp);
        view.setMaxLines(maxLines);
        view.setEllipsize(TextUtils.TruncateAt.END);
        return view;
    }

    private int resolveDescMaxLines(int defaultLines) {
        if (descMaxLines == null || descMaxLines < 1) {
            return defaultLines;
        }
        return descMaxLines;
    }

    @Nullable
    private Integer parseDescMaxLines(@Nullable Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        if (rawValue instanceof Number) {
            return ((Number) rawValue).intValue();
        }
        try {
            return Integer.parseInt(String.valueOf(rawValue));
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private boolean parseBoolean(@Nullable Object rawValue) {
        if (rawValue == null) {
            return false;
        }
        if (rawValue instanceof Boolean) {
            return (Boolean) rawValue;
        }
        return "true".equalsIgnoreCase(String.valueOf(rawValue))
                || "1".equals(String.valueOf(rawValue));
    }

    @Nullable
    private Integer parseDimensionPx(@Nullable Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        final float value;
        if (rawValue instanceof Number) {
            value = ((Number) rawValue).floatValue();
        } else {
            try {
                value = Float.parseFloat(String.valueOf(rawValue));
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        if (value <= 0) {
            return null;
        }
        return UIUtils.dp2px(context, value);
    }

    private void applyFixedWidth(@NonNull View view, @Nullable Integer widthPx) {
        if (widthPx == null || widthPx <= 0) {
            return;
        }
        final ViewGroup.LayoutParams params = view.getLayoutParams();
        params.width = widthPx;
        view.setLayoutParams(params);
    }

    private TextView createSourceView() {
        final TextView view = new TextView(context);
        view.setTextColor(Color.parseColor("#A18F76"));
        view.setTextSize(11);
        view.setText(TextUtils.isEmpty(nativeAdData.getTitle()) ? "精选推荐" : "优量精选");
        return view;
    }

    private Button createActionButton(int widthDp, int heightDp) {
        return createActionButton(widthDp, heightDp, false);
    }

    private Button createActionButton(int widthDp, int heightDp, boolean preferDownloadFallback) {
        final Button button = new Button(context);
        button.setAllCaps(false);
        button.setTextColor(Color.WHITE);
        button.setTextSize(13);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setPadding(0, 0, 0, 0);
        button.setMinWidth(0);
        button.setMinimumWidth(0);
        button.setMinHeight(0);
        button.setMinimumHeight(0);
        button.setText(resolveButtonText(preferDownloadFallback));
        button.setBackground(createRoundedDrawable("#EE8D35", 999));
        button.setLayoutParams(new LinearLayout.LayoutParams(
                UIUtils.dp2px(context, widthDp),
                UIUtils.dp2px(context, heightDp)
        ));
        return button;
    }

    private ImageView createMediaView(int radiusDp) {
        final ImageView imageView = new ImageView(context);
        imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        imageView.setBackground(createRoundedDrawable("#FFE7D4", radiusDp));
        imageView.setClipToOutline(true);
        return imageView;
    }

    private android.graphics.drawable.GradientDrawable createRoundedDrawable(String colorHex, int radiusDp) {
        final android.graphics.drawable.GradientDrawable drawable =
                new android.graphics.drawable.GradientDrawable();
        drawable.setColor(Color.parseColor(colorHex));
        drawable.setCornerRadius(UIUtils.dp2px(context, radiusDp));
        return drawable;
    }

    private String resolveButtonText() {
        return resolveButtonText(false);
    }

    private String resolveButtonText(boolean preferDownloadFallback) {
        if (!TextUtils.isEmpty(nativeAdData.getButtonText())) {
            return nativeAdData.getButtonText();
        }
        return preferDownloadFallback ? "立即下载" : "立即查看";
    }

    private String getPrimaryImageUrl() {
        if (!TextUtils.isEmpty(nativeAdData.getImgUrl())) {
            return nativeAdData.getImgUrl();
        }
        if (nativeAdData.getImgList() != null && !nativeAdData.getImgList().isEmpty()) {
            return nativeAdData.getImgList().get(0);
        }
        return "";
    }

    private int resolveViewWidthPx() {
        return viewWidthPx == null || viewWidthPx <= 0
                ? FrameLayout.LayoutParams.MATCH_PARENT
                : viewWidthPx;
    }

    private int resolveViewHeightPx() {
        return viewHeightPx == null || viewHeightPx <= 0
                ? FrameLayout.LayoutParams.MATCH_PARENT
                : viewHeightPx;
    }

    private int resolveImageWidthPx() {
        return imageWidthPx == null || imageWidthPx <= 0
                ? LinearLayout.LayoutParams.MATCH_PARENT
                : imageWidthPx;
    }

    private int resolveImageHeightPx() {
        return imageHeightPx == null || imageHeightPx <= 0
                ? UIUtils.dp2px(context, 148)
                : imageHeightPx;
    }

    private int resolveBannerImageHeightPx() {
        return imageHeightPx == null || imageHeightPx <= 0
                ? LinearLayout.LayoutParams.MATCH_PARENT
                : imageHeightPx;
    }

    private int resolveHorizontalImageHeightPx() {
        return imageHeightPx == null || imageHeightPx <= 0
                ? LinearLayout.LayoutParams.MATCH_PARENT
                : imageHeightPx;
    }

    private int resolveImageRadiusPx() {
        return imageRadiusPx == null || imageRadiusPx <= 0
                ? UIUtils.dp2px(context, 18)
                : imageRadiusPx;
    }

    private TextView createOverlayBadgeView() {
        final TextView badgeView = new TextView(context);
        badgeView.setText("广告");
        badgeView.setTextSize(11);
        badgeView.setTextColor(Color.WHITE);
        badgeView.setTypeface(Typeface.DEFAULT_BOLD);
        badgeView.setPadding(
                UIUtils.dp2px(context, 8),
                UIUtils.dp2px(context, 3),
                UIUtils.dp2px(context, 8),
                UIUtils.dp2px(context, 3)
        );
        badgeView.setBackground(createRoundedDrawable("#CC1F2329", 999));
        return badgeView;
    }

    private ImageView createMediaViewPx(int radiusPx) {
        final ImageView imageView = new ImageView(context);
        imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        final android.graphics.drawable.GradientDrawable drawable =
                new android.graphics.drawable.GradientDrawable();
        drawable.setColor(Color.parseColor("#FFE7D4"));
        drawable.setCornerRadius(radiusPx);
        imageView.setBackground(drawable);
        imageView.setClipToOutline(true);
        return imageView;
    }

    private String resolveStyleType(@Nullable Object rawStyleType) {
        final String value = rawStyleType == null ? "" : String.valueOf(rawStyleType);
        if (STYLE_HORIZONTAL_LIST_NATIVE.equals(value)) {
            return STYLE_HORIZONTAL_LIST_NATIVE;
        }
        if (STYLE_BANNER_ONLY_IMAGE_NATIVE.equals(value)) {
            return STYLE_BANNER_ONLY_IMAGE_NATIVE;
        }
        return STYLE_VERTICAL_LIST_NATIVE;
    }

    private void bindNativeAd() {
        final List<View> clickableViews = new ArrayList<View>();
        clickableViews.add(container);
        if (iconView != null) {
            clickableViews.add(iconView);
        }
        if (actionButton != null) {
            clickableViews.add(actionButton);
        }
        if (titleView != null) {
            clickableViews.add(titleView);
        }
        if (descView != null) {
            clickableViews.add(descView);
        }
        if (sourceView != null) {
            clickableViews.add(sourceView);
        }
        if (!mediaViews.isEmpty()) {
            clickableViews.addAll(mediaViews);
        }

        nativeAdData.bindAdToView(activity, container, null, clickableViews);
        if (!mediaViews.isEmpty()) {
            nativeAdData.bindImageViews(mediaViews, 0);
        }

        nativeAdData.setNativeAdEventListener(new NativeADEventListener() {
            @Override
            public void onADExposed() {
                sendEvent(AdEventAction.onAdExposure);
            }

            @Override
            public void onADClicked() {
                sendEvent(AdEventAction.onAdClicked);
            }

            @Override
            public void onADError(AdError error) {
                sendErrorEvent(error.getErrorCode(), error.getErrorMsg());
            }

            @Override
            public void onADStatusChanged() {
                sendEvent(AdEventAction.onAdPresent);
            }
        });
    }

    private void loadImage(final String imageUrl, final ImageView imageView) {
        if (TextUtils.isEmpty(imageUrl) || imageView == null) {
            return;
        }
        new Thread(new Runnable() {
            @Override
            public void run() {
                HttpURLConnection connection = null;
                InputStream inputStream = null;
                try {
                    connection = (HttpURLConnection) new URL(imageUrl).openConnection();
                    connection.setConnectTimeout(5000);
                    connection.setReadTimeout(5000);
                    connection.connect();
                    inputStream = connection.getInputStream();
                    final Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
                    if (bitmap != null) {
                        imageView.post(new Runnable() {
                            @Override
                            public void run() {
                                imageView.setImageBitmap(bitmap);
                            }
                        });
                    }
                } catch (Exception ignored) {
                } finally {
                    try {
                        if (inputStream != null) {
                            inputStream.close();
                        }
                    } catch (Exception ignored) {
                    }
                    if (connection != null) {
                        connection.disconnect();
                    }
                }
            }
        }).start();
    }
}
