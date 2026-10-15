package com.sshackers.batteryguardian;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {
    private TextView status, report;
    private LinearLayout root;
    private int ink = Color.rgb(28, 39, 52);
    private int muted = Color.rgb(94, 107, 120);
    private int accent = Color.rgb(20, 105, 180);

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        buildUi();
        analyze();
    }

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(22), dp(28), dp(22), dp(28));
        root.setBackgroundColor(Color.rgb(246, 249, 252));
        scroll.addView(root);

        TextView title = text("BATTERY ENHANCER", 25, ink, true);
        root.addView(title);
        TextView sub = text("Diagnostics • Safe optimization • Device health", 14, muted, false);
        LinearLayout.LayoutParams sp = params(-1, -2); sp.topMargin = dp(6); root.addView(sub, sp);

        status = text("Checking battery…", 17, ink, true);
        status.setPadding(dp(16), dp(16), dp(16), dp(16));
        status.setBackgroundColor(Color.WHITE);
        LinearLayout.LayoutParams cp = params(-1, -2); cp.topMargin = dp(22); root.addView(status, cp);

        Button run = new Button(this);
        run.setText("ANALYZE & OPTIMIZE");
        run.setTextSize(15);
        run.setTextColor(Color.WHITE);
        run.setAllCaps(false);
        run.setBackgroundTintList(android.content.res.ColorStateList.valueOf(accent));
        LinearLayout.LayoutParams bp = params(-1, -2); bp.topMargin = dp(16); root.addView(run, bp);
        run.setOnClickListener(v -> analyze());

        Button settings = new Button(this);
        settings.setText("Open Battery Settings");
        settings.setAllCaps(false);
        LinearLayout.LayoutParams setp = params(-1, -2); setp.topMargin = dp(6); root.addView(settings, setp);
        settings.setOnClickListener(v -> {
            try { startActivity(new Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)); }
            catch (Exception e) { startActivity(new Intent(Settings.ACTION_SETTINGS)); }
        });

        report = text("", 14, ink, false);
        report.setPadding(dp(16), dp(16), dp(16), dp(16));
        report.setBackgroundColor(Color.WHITE);
        LinearLayout.LayoutParams rp = params(-1, -2); rp.topMargin = dp(16); root.addView(report, rp);

        TextView note = text("Honest diagnostics: Android restricts third-party apps from force-clearing RAM, changing hidden power controls, or guaranteeing extra battery life. This app reports available battery data and offers safe, user-controlled settings.", 12, muted, false);
        LinearLayout.LayoutParams np = params(-1, -2); np.topMargin = dp(16); root.addView(note, np);
        setContentView(scroll);
    }

    private void analyze() {
        Intent battery = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        if (battery == null) {
            status.setText("Battery API unavailable");
            report.setText("Android did not return ACTION_BATTERY_CHANGED. Reopen the app and retry. If this persists on the custom ROM, collect a bug report/logcat; the app cannot repair a ROM-level API issue itself.");
            return;
        }

        int level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, 100);
        int pct = (level >= 0 && scale > 0) ? Math.round(level * 100f / scale) : -1;
        int temp = battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1); // tenths of °C
        int voltage = battery.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1); // mV
        int health = battery.getIntExtra(BatteryManager.EXTRA_HEALTH, -1);
        int plugged = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0);
        int state = battery.getIntExtra(BatteryManager.EXTRA_STATUS, -1);

        List<String> findings = new ArrayList<>();
        if (pct >= 0 && pct <= 15) findings.add("LOW CHARGE: " + pct + "%. Enable Battery Saver and reduce display brightness.");
        else if (pct >= 0 && pct < 30) findings.add("POWER RESERVE: " + pct + "%. Consider Battery Saver if you need the phone to last.");
        else if (pct >= 0) findings.add("Charge level: " + pct + "%.");

        if (temp >= 0) {
            float c = temp / 10f;
            findings.add(String.format(Locale.US, "Battery temperature: %.1f °C%s", c, c >= 45 ? " — HIGH; stop heavy use and let the phone cool." : c >= 40 ? " — warm; reduce gaming/video and charging load." : " — no high-temperature warning from this reading."));
        } else findings.add("Battery temperature: not exposed by this ROM.");

        if (voltage > 0) findings.add(String.format(Locale.US, "Battery voltage: %.2f V (raw Android reading).", voltage / 1000f));
        else findings.add("Battery voltage: unavailable.");

        findings.add("Battery health: " + healthName(health) + ".");
        findings.add("Power state: " + statusName(state) + (plugged != 0 ? " (power connected)" : " (not connected to power)") + ".");
        findings.add("API source: Android ACTION_BATTERY_CHANGED broadcast.");

        findings.add("");
        findings.add("SAFE ACTIONS");
        findings.add("• Review Battery usage in system Settings and identify apps with unusually high background use.");
        findings.add("• Use Battery Saver when you need longer runtime; reduce screen brightness and refresh/display activity.");
        findings.add("• If the percentage drops while connected to a charger, inspect the cable, adapter, USB port and battery hardware. Software cannot repair a failing charging circuit.");
        findings.add("");
        findings.add("LIMITATIONS");
        findings.add("• Battery capacity/cycle count and per-app drain may be hidden by this ROM or require privileged/system access.");
        findings.add("• No RAM clearing, app killing, cache deletion, or hidden system writes are performed.");
        findings.add("• This is a diagnostic baseline, not a guarantee of increased battery life.");

        status.setText((pct >= 0 ? pct + "% battery" : "Battery percentage unavailable") + (temp >= 0 ? "  •  " + String.format(Locale.US, "%.1f°C", temp / 10f) : ""));
        report.setText(join(findings));
    }

    private String healthName(int h) {
        switch (h) {
            case BatteryManager.BATTERY_HEALTH_GOOD: return "GOOD";
            case BatteryManager.BATTERY_HEALTH_OVERHEAT: return "OVERHEAT";
            case BatteryManager.BATTERY_HEALTH_DEAD: return "DEAD";
            case BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE: return "OVER-VOLTAGE";
            case BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE: return "UNSPECIFIED FAILURE";
            case BatteryManager.BATTERY_HEALTH_COLD: return "COLD";
            default: return "UNKNOWN / NOT EXPOSED";
        }
    }

    private String statusName(int s) {
        switch (s) {
            case BatteryManager.BATTERY_STATUS_CHARGING: return "CHARGING";
            case BatteryManager.BATTERY_STATUS_DISCHARGING: return "DISCHARGING";
            case BatteryManager.BATTERY_STATUS_FULL: return "FULL";
            case BatteryManager.BATTERY_STATUS_NOT_CHARGING: return "NOT CHARGING";
            default: return "UNKNOWN";
        }
    }

    private TextView text(String value, int size, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value); t.setTextSize(size); t.setTextColor(color);
        if (bold) t.setTypeface(null, android.graphics.Typeface.BOLD);
        return t;
    }
    private LinearLayout.LayoutParams params(int w, int h) { return new LinearLayout.LayoutParams(w, h); }
    private int dp(int v) { return Math.round(v * getResources().getDisplayMetrics().density); }
    private String join(List<String> lines) {
        StringBuilder b = new StringBuilder();
        for (String line : lines) b.append(line).append('\n');
        return b.toString().trim();
    }
}
