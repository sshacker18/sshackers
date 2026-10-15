package com.sshacker18.batterybrain

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Typeface
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {
    private lateinit var summary: TextView
    private lateinit var history: TextView
    private var batteryReceiverRegistered = false

    private val exportPicker = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.CreateDocument("text/csv")
    ) { uri: Uri? ->
        if (uri == null) return@registerForActivityResult
        try {
            contentResolver.openOutputStream(uri)?.use { output ->
                output.write(BatteryRepository.exportText(this).toByteArray(Charsets.UTF_8))
            } ?: throw IllegalStateException("Could not open destination")
            Toast.makeText(this, "Battery history exported", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Toast.makeText(this, "Export failed: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            refreshScreen()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildUi()
        captureNow()
        refreshScreen()
    }

    override fun onResume() {
        super.onResume()
        if (!batteryReceiverRegistered) {
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(batteryReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(batteryReceiver, filter)
            }
            batteryReceiverRegistered = true
        }
        refreshScreen()
    }

    override fun onPause() {
        if (batteryReceiverRegistered) {
            unregisterReceiver(batteryReceiver)
            batteryReceiverRegistered = false
        }
        super.onPause()
    }

    private fun buildUi() {
        val outer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(18), dp(20), dp(24))
            setBackgroundColor(0xFFF5F7FA.toInt())
        }
        val scroll = ScrollView(this)
        scroll.addView(outer)

        val title = TextView(this).apply {
            text = "Battery Brain"
            textSize = 28f
            setTextColor(0xFF142235.toInt())
            typeface = Typeface.DEFAULT_BOLD
        }
        outer.addView(title)
        outer.addView(text("POCO M2 Pro • LineageOS • Local-only battery history", 14f, 0xFF4B5B70.toInt()).also {
            it.setPadding(0, dp(4), 0, dp(16))
        })

        summary = text("Reading Android battery service…", 16f, 0xFF142235.toInt())
        outer.addView(summary)

        outer.addView(text("Actions", 18f, 0xFF142235.toInt(), true).also {
            it.setPadding(0, dp(18), 0, dp(8))
        })
        outer.addView(actionButton("Capture sample now") { captureNow(); refreshScreen() })
        outer.addView(actionButton("Enable 15-minute background samples") { startSampling() })
        outer.addView(actionButton("Stop background samples") { stopSampling() })
        outer.addView(actionButton("Export CSV for Python analysis") {
            val file = BatteryRepository.historyFile(this)
            if (!file.exists() || file.length() == 0L) {
                Toast.makeText(this, "No samples yet. Capture a sample first.", Toast.LENGTH_LONG).show()
            } else {
                exportPicker.launch("battery-history.csv")
            }
        })

        outer.addView(text("Recent samples", 18f, 0xFF142235.toInt(), true).also {
            it.setPadding(0, dp(18), 0, dp(8))
        })
        history = text("No saved samples yet.", 14f, 0xFF344256.toInt())
        outer.addView(history)

        outer.addView(text("Safe optimization guidance", 18f, 0xFF142235.toInt(), true).also {
            it.setPadding(0, dp(18), 0, dp(8))
        })
        outer.addView(text(
            "Battery Brain measures and reports; it does not kill apps, change hidden system settings, or require root. " +
                "Android may defer background samples, especially in Doze or under battery restrictions. " +
                "For best results, leave sampling enabled and export after a normal day.",
            14f, 0xFF344256.toInt()
        ))

        setContentView(scroll)
    }

    private fun captureNow() {
        try {
            val sample = BatteryRepository.capture(this)
            if (sample == null) {
                Toast.makeText(this, "Android did not return battery data", Toast.LENGTH_LONG).show()
                return
            }
            BatteryRepository.append(this, sample)
            Toast.makeText(this, "Sample saved: ${sample.levelPercent}%", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Toast.makeText(this, "Could not save sample: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun startSampling() {
        val request = PeriodicWorkRequestBuilder<BatterySnapshotWorker>(15, TimeUnit.MINUTES)
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "battery-brain-periodic-sampling",
            ExistingPeriodicWorkPolicy.UPDATE,
            request
        )
        Toast.makeText(this, "Background sampling enabled (Android may defer runs)", Toast.LENGTH_LONG).show()
    }

    private fun stopSampling() {
        WorkManager.getInstance(this).cancelUniqueWork("battery-brain-periodic-sampling")
        Toast.makeText(this, "Background sampling stopped", Toast.LENGTH_SHORT).show()
    }

    private fun refreshScreen() {
        if (!::summary.isInitialized) return
        val sample = BatteryRepository.capture(this)
        val recent = BatteryRepository.recent(this, 8)
        summary.text = if (sample == null) {
            "Battery data is not currently available."
        } else {
            buildString {
                append("Charge: ${sample.levelPercent}%\n")
                append("Temperature: ${sample.temperatureC?.let { String.format("%.1f °C", it) } ?: "Unavailable"}\n")
                append("Voltage: ${sample.voltageMv?.let { "${it} mV" } ?: "Unavailable"}\n")
                append("Power: ${sample.status.replace('_', ' ')}${if (sample.plugged) " • plugged in" else ""}\n")
                append("Battery-reported health: ${sample.health.replace('_', ' ')}\n")
                append("Current reading: ${sample.currentNowUa?.let { "${it} µA" } ?: "Unavailable"}\n")
                append("History samples: ${recent.size}")
            }
        }
        history.text = if (recent.isEmpty()) "No history yet. Capture a sample now or enable background sampling." else {
            recent.asReversed().joinToString("\n") { s ->
                val time = runCatching {
                    DateTimeFormatter.ofPattern("HH:mm:ss").withZone(ZoneId.systemDefault()).format(Instant.parse(s.timestamp))
                }.getOrDefault(s.timestamp)
                "$time  ${s.levelPercent}%  ${s.temperatureC?.let { String.format("%.1f°C", it) } ?: "temp n/a"}  ${s.status}"
            }
        }
    }

    private fun actionButton(label: String, action: () -> Unit): Button = Button(this).apply {
        text = label
        isAllCaps = false
        setOnClickListener { action() }
        layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = dp(5)
        }
    }

    private fun text(value: String, size: Float, color: Int, bold: Boolean = false) = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(color)
        if (bold) typeface = Typeface.DEFAULT_BOLD
        setPadding(0, dp(3), 0, dp(3))
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
