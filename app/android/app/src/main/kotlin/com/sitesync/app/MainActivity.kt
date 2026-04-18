package com.sitesync.app

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.sitesync.app/file_opener",
        ).setMethodCallHandler { call, result ->
            if (call.method != "openFileChooser") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val mimeType = call.argument<String>("mimeType") ?: "*/*"
            val chooserTitle = call.argument<String>("title") ?: "Open file with"

            if (path.isNullOrBlank()) {
                result.success(false)
                return@setMethodCallHandler
            }

            result.success(openFileChooser(path, mimeType, chooserTitle))
        }
    }

    private fun openFileChooser(path: String, mimeType: String, chooserTitle: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) {
                return false
            }

            val authority = "${applicationContext.packageName}.fileProvider.com.crazecoder.openfile"
            val uri: Uri = FileProvider.getUriForFile(applicationContext, authority, file)
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addCategory(Intent.CATEGORY_DEFAULT)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                clipData = ClipData.newRawUri(file.name, uri)
            }

            val resolveInfos = packageManager.queryIntentActivities(viewIntent, 0)
            if (resolveInfos.isEmpty()) {
                return false
            }

            resolveInfos.forEach { info ->
                grantUriPermission(
                    info.activityInfo.packageName,
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            }

            val chooserIntent = Intent.createChooser(viewIntent, chooserTitle).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                clipData = ClipData.newRawUri(file.name, uri)
            }

            startActivity(chooserIntent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
