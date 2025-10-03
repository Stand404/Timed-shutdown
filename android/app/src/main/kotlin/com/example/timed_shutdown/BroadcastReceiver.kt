package com.example.timed_shutdown

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        Log.d("BootReceiver", "开机完成 -> 启动后台服务")
        
        // 检查是否有需要恢复的任务
        val sp = ctx.getSharedPreferences("alarm_record", Context.MODE_PRIVATE)
        if (sp.all.isNotEmpty()) {
            Log.d("BootReceiver", "有任务需要恢复，启动后台服务")
            
            val serviceIntent = Intent(ctx, AutoShutdownService::class.java).apply { 
                action = "RESTORE" 
            }
            ctx.startService(serviceIntent)
        } else {
            Log.d("BootReceiver", "无任务需要恢复")
        }
    }
}