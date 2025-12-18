package com.example.aerosaur_2nd_sem

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channel = "com.example.aerosaur_2nd_sem/system_settings"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "openWifiSettings" -> {
            try {
              startActivity(Intent(Settings.ACTION_WIFI_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
              result.success(null)
            } catch (e: Exception) {
              try {
                startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(null)
              } catch (e2: Exception) {
                result.error("UNAVAILABLE", "Unable to open settings.", null)
              }
            }
          }
          else -> result.notImplemented()
        }
      }
  }
}
