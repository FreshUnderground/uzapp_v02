package com.investeegroup.uzaapp

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.investeegroup.uzaapp/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareToChat" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val filePath = call.argument<String>("filePath")
                        result.success(shareToWhatsApp(phone, text, filePath))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareToWhatsApp(phone: String, text: String, filePath: String?): Boolean {
        val cleanPhone = phone.replace(Regex("[^0-9]"), "")
        if (cleanPhone.isEmpty()) return false

        val packages = listOf("com.whatsapp", "com.whatsapp.w4b")
        for (pkg in packages) {
            val intent = buildShareIntent(cleanPhone, text, filePath, pkg) ?: continue
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }
        return false
    }

    private fun buildShareIntent(
        cleanPhone: String,
        text: String,
        filePath: String?,
        packageName: String,
    ): Intent? {
        val intent = Intent(Intent.ACTION_SEND)
        if (!filePath.isNullOrEmpty()) {
            val file = File(filePath)
            if (!file.exists()) return null
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
            intent.type = "image/jpeg"
            intent.putExtra(Intent.EXTRA_STREAM, uri)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } else {
            intent.type = "text/plain"
        }
        intent.putExtra(Intent.EXTRA_TEXT, text)
        intent.putExtra("jid", "$cleanPhone@s.whatsapp.net")
        intent.setPackage(packageName)
        return intent
    }
}
