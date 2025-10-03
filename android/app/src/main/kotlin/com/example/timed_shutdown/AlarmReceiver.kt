package com.example.timed_shutdown

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "收到闹钟广播: ${intent.action}")
        
        when (intent.action) {
            "com.example.timed_shutdown.ALARM" -> {
                val taskId = intent.getStringExtra("taskId")
                Log.d("AlarmReceiver", "执行任务: $taskId")
                
                // 启动服务执行关机操作
                val serviceIntent = Intent(context, AutoShutdownService::class.java).apply {
                    action = "EXEC"
                    putExtra("taskId", taskId)
                }
                context.startService(serviceIntent)
                
                // 对于 Android 6.0+ 的设备，需要重新设置下一次闹钟
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    resetAlarmForNextDay(context, taskId)
                }
            }
        }
    }
    
    // 为 Android 6.0+ 设备重新设置下一次闹钟
    private fun resetAlarmForNextDay(context: Context, taskId: String?) {
        if (taskId == null) return
        
        val sp = context.getSharedPreferences("alarm_record", Context.MODE_PRIVATE)
        val timeString = sp.getString(taskId, null) ?: return
        
        Log.d("AlarmReceiver", "为 Android 6.0+ 重新设置闹钟: $taskId -> $timeString")
        
        val serviceIntent = Intent(context, AutoShutdownService::class.java).apply {
            action = "ADD"
            putExtra("taskId", taskId)
            putExtra("time", timeString)
        }
        context.startService(serviceIntent)
    }
}