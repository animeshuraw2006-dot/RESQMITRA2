package com.example.resq_mitra

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "resq_mitra/native_sms"
    private val smsPermissionRequestCode = 4127
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureSmsPermission" -> ensureSmsPermission(result)
                    "sendSms" -> sendSms(call.argument<String>("phone"), call.argument<String>("message"), result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureSmsPermission(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_request_in_progress", "An SMS permission request is already active.", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.SEND_SMS), smsPermissionRequestCode)
    }

    @Deprecated("Deprecated in Android API; retained for compatibility with Flutter embedding")
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == smsPermissionRequestCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun sendSms(phone: String?, message: String?, result: MethodChannel.Result) {
        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
            result.error("invalid_arguments", "Phone number and message are required.", null)
            return
        }
        if (checkSelfPermission(Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
            result.error("permission_denied", "SMS permission has not been granted.", null)
            return
        }
        try {
            val manager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            val parts = manager.divideMessage(message)
            if (parts.size > 1) {
                manager.sendMultipartTextMessage(phone, null, parts, null, null)
            } else {
                manager.sendTextMessage(phone, null, message, null, null)
            }
            result.success("submitted")
        } catch (e: Exception) {
            result.error("sms_send_failed", e.message ?: "Android could not submit the SMS.", null)
        }
    }
}
