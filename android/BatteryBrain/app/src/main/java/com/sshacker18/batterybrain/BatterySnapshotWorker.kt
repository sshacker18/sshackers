package com.sshacker18.batterybrain

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class BatterySnapshotWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        return try {
            val sample = BatteryRepository.capture(applicationContext) ?: return Result.retry()
            BatteryRepository.append(applicationContext, sample)
            Result.success()
        } catch (_: Exception) {
            Result.retry()
        }
    }
}
