package com.example.event_tracker

import android.content.Intent
import android.provider.Settings
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ScrollServices"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName);
        channel.setMethodCallHandler { call, result ->
            if (call.method == "showToast") {
                Toast.makeText(this, "hello", Toast.LENGTH_LONG).show()
            } else if (call.method == "startAccessibilityService") {
                startAccessibilityService()
                result.success("Accessibility Service Started")
            }
        }
    }

    private fun startAccessibilityService() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
}
