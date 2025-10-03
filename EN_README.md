<div align="center">
    <h1>timed_shutdown</h1>
    <img width=100 src="icos/图标.svg">

A Flutter-based Android app for scheduled power-off.
</div>

## English | [中文](README.md)

### Features
- Create / edit / delete scheduled shutdown tasks  
- Automatic shutdown at the set time (Root required)  
- Auto-restore tasks after reboot

### Important Notes
1. **Android only and device must be rooted**  
2. After enabling a task, if the scheduled time is earlier than the current time, it will trigger the next day  
3. If you move the system time forward, **be sure to reopen the App**, otherwise the task will not take effect
4. Shutdown is a hard operation—unsaved data may be lost; use with caution  

### Download
APK files (armeabi-v7a, arm64-v8a, x86_64) are available on the GitHub Releases page  
[https://github.com/stand404/Timed-shutdown/releases](https://github.com/stand404/Timed-shutdown/releases)

### Build
```bash
git clone https://github.com/stand404/timed_shutdown.git
cd timed_shutdown
flutter pub get
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### License
MIT License  
Copyright © 2025 Stand
