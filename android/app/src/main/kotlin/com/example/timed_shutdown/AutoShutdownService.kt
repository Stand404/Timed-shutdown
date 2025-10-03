package com.example.timed_shutdown

import android.app.*
import android.content.*
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log
import java.util.Calendar

class AutoShutdownService : Service() {

    companion object {
        private const val TAG = "AutoShutdownService"
        private const val NOTI_ID = 2001        // 前台通知 id
        private const val CHANNEL_ID = "exec"   // 通知渠道 id
        private const val DAILY_INTERVAL = AlarmManager.INTERVAL_DAY // 24小时间隔
    }

    private val sp by lazy {
        getSharedPreferences("alarm_record", Context.MODE_PRIVATE)
    }

    /* ======================== 生命周期 ======================== */
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "【onCreate】")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "【onDestroy】")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /* ======================== 入口 ======================== */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "【onStartCommand】收到 intent: ${intent?.action}, extras: ${intent?.extras}")
        // 必须在5秒内调用 startForeground()，所以先抬前台
        setupBackgroundNotification()

        // 然后处理具体的业务逻辑
        when (intent?.action) {
            "ADD"     -> handleAdd(intent)
            "DEL"     -> handleDel(intent)
            "EXEC"    -> handleExec(intent)
            "RESTORE" -> handleRestore()
            else      -> Log.w(TAG, "未知 action=${intent?.action}")
        }

        return START_STICKY
    }

    /* -------------------- 设置后台通知 -------------------- */
    private fun setupBackgroundNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val ch = NotificationChannel(
                    CHANNEL_ID,
                    "定时任务执行",
                    NotificationManager.IMPORTANCE_LOW
                )
                ch.description = "显示后台运行的定时关机任务"
                nm.createNotificationChannel(ch)
            }

            // 创建低优先级通知（不调用 startForeground）
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("定时关机")
                .setContentText("服务正在后台运行")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(false) // 非持续通知
                .setAutoCancel(false)
                .build()

            // 只发送通知，不设置为前台服务
            nm.notify(NOTI_ID, notification)
            Log.d(TAG, "【setupBackgroundNotification】后台通知已设置")
        } catch (e: Exception) {
            Log.e(TAG, "【setupBackgroundNotification】设置通知失败", e)
        }
    }

    /* -------------------- 2. 新增/覆盖任务 -------------------- */
    private fun handleAdd(intent: Intent) {
        val taskId = intent.getStringExtra("taskId") ?: return
        val timeString = intent.getStringExtra("time") ?: return // 格式: "HH:mm"
        
        Log.d(TAG, "【ADD】处理任务 $taskId -> $timeString")

        // 如果任务已存在，先取消旧的
        if (sp.contains(taskId)) {
            Log.d(TAG, "【ADD】任务已存在，覆盖: $taskId")
            cancelAlarm(taskId)
        }

        // 存储任务信息
        sp.edit().putString(taskId, timeString).apply()
        
        // 设置每日重复闹钟
        setDailyRepeatingAlarm(taskId, timeString)
    }

    /* -------------------- 3. 删除任务 -------------------- */
    private fun handleDel(intent: Intent) {
        val taskId = intent.getStringExtra("taskId") ?: return

        sp.edit().remove(taskId).apply()
        Log.d(TAG, "【DEL】移除任务 $taskId")

        cancelAlarm(taskId)
        
        // 如果没有任务了，可以停掉服务
        if (sp.all.isEmpty()) {
            Log.d(TAG, "【DEL】已无任务，停止服务")
            stopForeground(true)
            stopSelf()
        }
    }

    /* -------------------- 4. 闹钟到点 -------------------- */
    private fun handleExec(intent: Intent) {
        val taskId = intent.getStringExtra("taskId") ?: return
        Log.d(TAG, "【EXEC】执行任务 $taskId")
        
        // 执行关机操作（需 Root）
        try {
            Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot -p"))
            Log.d(TAG, "【EXEC】关机命令已发送")
        } catch (e: Exception) {
            Log.e(TAG, "关机失败", e)
        }
        
        // 检查是否还有其他任务
        if (sp.all.isEmpty()) {
            Log.d(TAG, "【EXEC】已无任务，停止服务")
            stopForeground(true)
            stopSelf()
        }
    }

    /* -------------------- 5. 开机自启恢复 -------------------- */
    private fun handleRestore() {
        Log.d(TAG, "【RESTORE】开始恢复闹钟")
        
        sp.all.forEach { (taskId, timeAny) ->
            val timeString = timeAny as? String ?: return@forEach
            
            Log.d(TAG, "【RESTORE】恢复任务: $taskId -> $timeString")
            setDailyRepeatingAlarm(taskId, timeString)
        }
        
        // 如果没有任务，自动停止服务
        if (sp.all.isEmpty()) {
            Log.d(TAG, "【RESTORE】无任务需要恢复，停止服务")
            stopForeground(true)
            stopSelf()
        }
    }

    /* ======================== 闹钟工具 ======================== */
    private fun setDailyRepeatingAlarm(taskId: String, timeString: String) {
        // 解析时间字符串 "HH:mm"
        val parts = timeString.split(":")
        if (parts.size != 2) {
            Log.e(TAG, "【setDailyRepeatingAlarm】时间格式错误: $timeString")
            return
        }
        
        val hour = parts[0].toIntOrNull() ?: return
        val minute = parts[1].toIntOrNull() ?: return
        
        // 计算第一次触发时间（下一次符合条件的时间）
        val firstTriggerTime = calculateFirstTriggerTime(hour, minute)

        val pi = PendingIntent.getBroadcast(
            applicationContext,
            taskId.hashCode(),
            Intent(applicationContext, AlarmReceiver::class.java).apply {
                action = "com.example.timed_shutdown.ALARM"
                putExtra("taskId", taskId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val mgr = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6.0+ 使用 setExactAndAllowWhileIdle 设置重复闹钟
            mgr.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, firstTriggerTime, pi)
            // 注意：setExactAndAllowWhileIdle 不支持直接设置重复，需要在触发后重新设置
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            // Android 4.4+ 使用 setExact 设置重复闹钟
            mgr.setExact(AlarmManager.RTC_WAKEUP, firstTriggerTime, pi)
        } else {
            // 旧版本使用 setRepeating（但注意在 Android 4.4+ 上可能不精确）
            mgr.setRepeating(AlarmManager.RTC_WAKEUP, firstTriggerTime, DAILY_INTERVAL, pi)
        }
        
        Log.d(TAG, "【setDailyRepeatingAlarm】已注册每日任务 $taskId, 时间: $timeString, 首次触发: $firstTriggerTime")
    }

    // 计算第一次触发时间
    private fun calculateFirstTriggerTime(hour: Int, minute: Int): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        
        val currentTime = System.currentTimeMillis()
        val triggerTime = calendar.timeInMillis
        
        // 如果今天的时间已经过了，就设置到明天
        return if (triggerTime <= currentTime) {
            calendar.add(Calendar.DAY_OF_MONTH, 1)
            calendar.timeInMillis
        } else {
            triggerTime
        }
    }

    private fun cancelAlarm(taskId: String) {
        val pi = PendingIntent.getBroadcast(
            applicationContext,
            taskId.hashCode(),
            Intent(applicationContext, AlarmReceiver::class.java).apply {
                action = "com.example.timed_shutdown.ALARM"
                putExtra("taskId", taskId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val mgr = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        mgr.cancel(pi)
        Log.d(TAG, "【cancelAlarm】已取消 $taskId")
    }
}