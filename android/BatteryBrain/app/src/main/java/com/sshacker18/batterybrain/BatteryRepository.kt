package com.sshacker18.batterybrain

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

data class BatterySample(
    val timestamp: String,
    val levelPercent: Int,
    val temperatureC: Double?,
    val voltageMv: Int?,
    val plugged: Boolean,
    val status: String,
    val health: String,
    val currentNowUa: Int?,
    val chargeCounterUah: Int?
) {
    fun toCsv(): String = listOf(
        timestamp, levelPercent.toString(), temperatureC?.let { String.format(Locale.US, "%.1f", it) } ?: "",
        voltageMv?.toString() ?: "", if (plugged) "1" else "0", status, health,
        currentNowUa?.toString() ?: "", chargeCounterUah?.toString() ?: ""
    ).joinToString(",")
}

object BatteryRepository {
    private const val FILE_NAME = "battery-history.csv"
    private const val HEADER =
        "timestamp,level_percent,temperature_c,voltage_mv,plugged,status,health,current_now_ua,charge_counter_uah\n"

    fun historyFile(context: Context): File = File(context.filesDir, FILE_NAME)

    fun capture(context: Context): BatterySample? {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return null
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        if (level < 0 || scale <= 0) return null

        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        fun available(value: Int): Int? = if (value == Int.MIN_VALUE || value < 0) null else value

        val tempRaw = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
        val voltageRaw = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, Int.MIN_VALUE)
        val pluggedRaw = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val statusRaw = intent.getIntExtra(BatteryManager.EXTRA_STATUS, BatteryManager.BATTERY_STATUS_UNKNOWN)
        val healthRaw = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN)

        return BatterySample(
            timestamp = Instant.now().toString(),
            levelPercent = ((level * 100f) / scale).toInt().coerceIn(0, 100),
            temperatureC = if (tempRaw == Int.MIN_VALUE || tempRaw < 0) null else tempRaw / 10.0,
            voltageMv = available(voltageRaw),
            plugged = pluggedRaw != 0,
            status = statusName(statusRaw),
            health = healthName(healthRaw),
            currentNowUa = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW).let {
                if (it == Int.MIN_VALUE) null else it
            },
            chargeCounterUah = available(batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER))
        )
    }

    fun append(context: Context, sample: BatterySample) {
        val file = historyFile(context)
        if (!file.exists() || file.length() == 0L) file.writeText(HEADER)
        file.appendText(sample.toCsv() + "\n")
    }

    fun recent(context: Context, count: Int = 8): List<BatterySample> {
        val file = historyFile(context)
        if (!file.isFile) return emptyList()
        return file.readLines().drop(1).asReversed().take(count).mapNotNull { line ->
            val p = line.split(",")
            if (p.size < 9) return@mapNotNull null
            BatterySample(
                timestamp = p[0],
                levelPercent = p[1].toIntOrNull() ?: return@mapNotNull null,
                temperatureC = p[2].toDoubleOrNull(),
                voltageMv = p[3].toIntOrNull(),
                plugged = p[4] == "1",
                status = p[5],
                health = p[6],
                currentNowUa = p[7].toIntOrNull(),
                chargeCounterUah = p[8].toIntOrNull()
            )
        }
    }

    fun exportText(context: Context): String = historyFile(context).takeIf { it.isFile }?.readText() ?: HEADER

    fun statusName(value: Int): String = when (value) {
        BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
        BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
        BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
        BatteryManager.BATTERY_STATUS_FULL -> "full"
        else -> "unknown"
    }

    private fun healthName(value: Int): String = when (value) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheat"
        BatteryManager.BATTERY_HEALTH_DEAD -> "dead"
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "over_voltage"
        BatteryManager.BATTERY_HEALTH_COLD -> "cold"
        else -> "unknown"
    }
}
