<div align="center">
    <h1>timed_shutdown</h1>
    <img width=100 src="icos\图标.svg">

一款基于Flutter的安卓定时关机APP
</div>

## 中文 | [English](EN_README.md)

### 功能
- 创建 / 编辑 / 删除定时关机任务  
- 到点自动执行关机（需 Root）  
- 重启后自动恢复任务

### 注意事项
1. **仅支持 Android 且设备已 Root**  
2. 开启任务后，如果定时早于当前时间，第二天才会触发  
3. 若修改系统时间提前，**务必重新打开 App**，否则任务不会生效
4. 关机为硬操作，未保存数据可能丢失，请谨慎使用  

### 下载
GitHub Releases 页面提供 APK（arm64-v7a、arm64-v8a、x86_64）  
[https://github.com/stand404/Timed-shutdown/releases](https://github.com/stand404/Timed-shutdown/releases)

### 构建
```bash
git clone https://github.com/stand404/timed_shutdown.git
cd timed_shutdown
flutter pub get
flutter build apk --release
```
输出：`build/app/outputs/flutter-apk/app-release.apk`

### 开源协议
MIT License  
Copyright © 2025 Stand
