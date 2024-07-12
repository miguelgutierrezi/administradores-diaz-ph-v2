package com.gutierrez.administradores_diaz_ph

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "alarm_permission"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isExactAlarmPermissionGranted" -> {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val isGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            alarmManager.canScheduleExactAlarms()
                        } else {
                            true // Permiso concedido automáticamente en versiones anteriores
                        }
                        result.success(isGranted)
                    }

                    "requestExactAlarmPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val alarmManager =
                                getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            if (alarmManager.canScheduleExactAlarms()) {
                                result.success(true) // Permiso ya concedido
                            } else {
                                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                startActivity(intent)
                                result.success(true)
                            }
                        } else {
                            result.success(false) // No es necesario solicitar permiso en versiones anteriores
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}