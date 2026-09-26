package com.population.population_mobile

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.population/install_apk"

    companion object {
        @Volatile
        var installResultCode: Int = -999
        @Volatile
        var installResultMsg: String? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val path = call.argument<String>("path")
                if (path != null) {
                    installResultCode = -999
                    installResultMsg = null
                    try {
                        installApkSilent(path)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "APK path is null", null)
                }
            } else if (call.method == "getInstallResult") {
                if (installResultCode == -999) {
                    result.success(mapOf("status" to "pending"))
                } else if (installResultCode == PackageInstaller.STATUS_SUCCESS) {
                    result.success(mapOf("status" to "success"))
                } else {
                    result.success(mapOf("status" to "error", "message" to (installResultMsg ?: "未知错误")))
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun installApkSilent(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw Exception("APK file not found: $path")
        }

        val packageInstaller = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)

        val sessionId = packageInstaller.createSession(params)
        packageInstaller.openSession(sessionId).use { session ->
            file.inputStream().use { input ->
                session.openWrite("population_app.apk", 0, file.length()).use { output ->
                    input.copyTo(output)
                    session.fsync(output)
                }
            }

            val intent = Intent(this, InstallResultReceiver::class.java)
            intent.putExtra("sessionId", sessionId)
            val pendingIntent = PendingIntent.getBroadcast(
                this, sessionId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            session.commit(pendingIntent.intentSender)
        }
    }
}

class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, -999)
        val msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)

        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirmIntent = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                confirmIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                confirmIntent?.let { context.startActivity(it) }
            }
            else -> {
                MainActivity.installResultCode = status
                MainActivity.installResultMsg = msg
            }
        }
    }
}
