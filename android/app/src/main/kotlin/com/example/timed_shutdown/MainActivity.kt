package com.example.timed_shutdown

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.net.Uri
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "AutoShutdown"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "【configureFlutterEngine】MethodChannel 初始化")

        try {
            Runtime.getRuntime().exec("su")
            Log.d(TAG, "【EXEC】申请root权限")
        } catch (e: Exception) {
            Log.e(TAG, "申请root权限失败", e)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "auto_shutdown")
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "【MethodCall】method=${call.method}")
                
                when (call.method) {
                    "enable" -> handleEnable(call, result)
                    "disable" -> handleDisable(call, result)
                    "checkAlarmPermission" -> {
                        val hasPermission = checkAlarmPermission()
                        result.success(hasPermission)
                    }
                    "checkNotificationPermission" -> {
                        val hasPermission = checkNotificationPermission()
                        result.success(hasPermission)
                    }
                    "requestAlarmPermission" -> {
                        requestAlarmPermission()
                        result.success(true)
                    }
                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(true)
                    }
                    else -> {
                        Log.d(TAG, "【MethodCall】未实现的方法：${call.method}")
                        result.notImplemented()
                    }
                }
            }
    }

    /* -------------------- 通知权限检查 -------------------- */
    private fun checkNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return NotificationManagerCompat.from(this).areNotificationsEnabled()
        }
        return true // Android 13 以下默认有权限
    }

    /* -------------------- 通知权限请求 -------------------- */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // 跳转到通知权限设置页面
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
            startActivity(intent)
        }
    }

    /* -------------------- 闹钟权限检查 -------------------- */
    private fun checkAlarmPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val hasPermission = alarmManager.canScheduleExactAlarms()
            Log.d(TAG, "【checkAlarmPermission】$hasPermission")
            return hasPermission
        }
        return true // Android 12 以下不需要特殊权限
    }

    /* -------------------- 精确闹钟权限请求 -------------------- */
    private fun requestAlarmPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!checkAlarmPermission()) {
                // 跳转到精确闹钟权限设置页面
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                intent.data = Uri.parse("package:${packageName}")
                startActivity(intent)
            }
        }
    }

    /* -------------------- 处理方法 -------------------- */
    private fun handleEnable(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId") ?: run {
            result.error("INVALID_ARGUMENT", "taskId 不能为空", null)
            return
        }
        val time = call.argument<String>("time") ?: run {
            result.error("INVALID_ARGUMENT", "time 不能为空", null)
            return
        }
        
        Log.d(TAG, "【enable】添加任务: $taskId, 时间: $time")

        // 检查闹钟权限（必须要有）
        if (!checkAlarmPermission()) {
            result.error("ALARM_PERMISSION_DENIED", "需要精确闹钟权限", null)
            return
        }

        try {
            val intent = Intent(this, AutoShutdownService::class.java).apply {
                action = "ADD"
                putExtra("taskId", taskId)
                putExtra("time", time)
            }
            
            startService(intent) // 直接使用 startService，让服务自己处理前台状态
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "【enable】启动服务失败", e)
            result.error("NATIVE_ERROR", "注册闹钟失败：${e.message}", null)
        }
    }

    private fun handleDisable(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId") ?: run {
            result.error("INVALID_ARGUMENT", "taskId 不能为空", null)
            return
        }
        
        Log.d(TAG, "【disable】删除任务: $taskId")

        try {
            val intent = Intent(this, AutoShutdownService::class.java).apply {
                action = "DEL"
                putExtra("taskId", taskId)
            }
            startService(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "【disable】停止服务失败", e)
            result.error("NATIVE_ERROR", "取消闹钟失败：${e.message}", null)
        }
    }
}