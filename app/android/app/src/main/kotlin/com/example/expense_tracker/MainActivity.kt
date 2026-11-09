package com.example.expense_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_POLICY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareExpenseDirectory" -> prepareExpenseDirectory(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareExpenseDirectory(result: MethodChannel.Result) {
        try {
            val directory = applicationContext.noBackupFilesDir
            if (!directory.exists() && !directory.mkdirs()) {
                result.error(
                    "privacyPolicyUnavailable",
                    "Protected storage is unavailable",
                    null,
                )
                return
            }

            if (!directory.isDirectory || !directory.canWrite()) {
                result.error(
                    "privacyPolicyUnavailable",
                    "Protected storage is not writable",
                    null,
                )
                return
            }

            val canonicalPath = directory.canonicalPath
            val expectedPath = applicationContext.noBackupFilesDir.canonicalPath
            val cachePath = applicationContext.cacheDir.canonicalPath
            if (canonicalPath != expectedPath ||
                canonicalPath == cachePath ||
                canonicalPath.startsWith("$cachePath${File.separator}")
            ) {
                result.error(
                    "privacyPolicyUnavailable",
                    "Protected storage could not be verified",
                    null,
                )
                return
            }

            result.success(canonicalPath)
        } catch (_: Exception) {
            result.error(
                "privacyPolicyUnavailable",
                "Protected storage could not be verified",
                null,
            )
        }
    }

    companion object {
        private const val STORAGE_POLICY_CHANNEL = "expense_tracker/storage_policy"
    }
}
