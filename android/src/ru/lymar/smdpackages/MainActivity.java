package ru.lymar.smdpackages;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.content.Context;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.View;
import android.view.Window;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
    private WebView web;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        web = new WebView(this);
        setContentView(web);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setTextZoom(100);
        web.setWebViewClient(new WebViewClient());
        web.addJavascriptInterface(new Bridge(), "Android");
        applyBars(false);
        if (savedInstanceState != null) web.restoreState(savedInstanceState);
        else web.loadUrl("file:///android_asset/index.html");
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        web.saveState(out);
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("(window.appBack&&window.appBack())?'1':'0'", v -> {
            if (v == null || !v.contains("1")) MainActivity.super.onBackPressed();
        });
    }

    private void applyBars(boolean dark) {
        Window w = getWindow();
        w.setStatusBarColor(dark ? Color.parseColor("#15324f") : Color.parseColor("#0b5cad"));
        w.setNavigationBarColor(dark ? Color.parseColor("#1a2129") : Color.WHITE);
        if (Build.VERSION.SDK_INT >= 26) {
            View d = w.getDecorView();
            int f = d.getSystemUiVisibility();
            if (dark) f &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
            else f |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
            d.setSystemUiVisibility(f);
        }
    }

    private void toast(String m) {
        runOnUiThread(() -> Toast.makeText(MainActivity.this, m, Toast.LENGTH_LONG).show());
    }

    class Bridge {
        @JavascriptInterface
        public void copy(String text) {
            runOnUiThread(() -> {
                ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                cm.setPrimaryClip(ClipData.newPlainText("SMD", text));
                if (Build.VERSION.SDK_INT < 33) Toast.makeText(MainActivity.this, "Скопировано", Toast.LENGTH_SHORT).show();
            });
        }

        @JavascriptInterface
        public void setDark(boolean dark) {
            runOnUiThread(() -> applyBars(dark));
        }

        @JavascriptInterface
        public void saveCsv(String name, String text) {
            byte[] data = text.getBytes(StandardCharsets.UTF_8);
            try {
                if (Build.VERSION.SDK_INT >= 29) {
                    ContentValues cv = new ContentValues();
                    cv.put(MediaStore.MediaColumns.DISPLAY_NAME, name);
                    cv.put(MediaStore.MediaColumns.MIME_TYPE, "text/csv");
                    cv.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
                    Uri uri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv);
                    if (uri == null) throw new Exception("MediaStore");
                    try (OutputStream os = getContentResolver().openOutputStream(uri)) { os.write(data); }
                    toast("Сохранено в «Загрузки»: " + name);
                } else {
                    File dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
                    if (dir != null && !dir.exists()) dir.mkdirs();
                    File f = new File(dir, name);
                    try (FileOutputStream os = new FileOutputStream(f)) { os.write(data); }
                    toast("Сохранено: " + f.getAbsolutePath());
                }
            } catch (Exception e) {
                toast("Ошибка сохранения: " + e.getMessage());
            }
        }
    }
}
