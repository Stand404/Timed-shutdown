import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _platform = MethodChannel('auto_shutdown');

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  // 权限状态存储
  Map<String, dynamic> _permissionState = {};

  /* ---------- 初始化 ---------- */
  Future<void> initialize() async {
    await _loadPermissionState();
  }

  /* ---------- 权限状态文件 I/O ---------- */
  Future<File> get _permissionFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/permissions.json');
  }

  Future<void> _loadPermissionState() async {
    final file = await _permissionFile;
    if (!await file.exists()) {
      _permissionState = {
        'notification_suggested': false,
      };
      return;
    }
    
    try {
      final raw = await file.readAsString();
      _permissionState = jsonDecode(raw);
    } catch (e) {
      _permissionState = {
        'notification_suggested': false,
      };
    }
  }

  Future<void> _savePermissionState() async {
    final file = await _permissionFile;
    final encoded = jsonEncode(_permissionState);
    await file.writeAsString(encoded);
  }

  /* ---------- 权限检查方法 ---------- */
  // 检查精确闹钟权限
  Future<bool> checkAlarmPermission() async {
    try {
      final hasPermission = await _platform.invokeMethod<bool>('checkAlarmPermission');
      return hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }

  // 检查通知权限
  Future<bool> checkNotificationPermission() async {
    try {
      final hasPermission = await _platform.invokeMethod<bool>('checkNotificationPermission');
      return hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }

  // 请求精确闹钟权限
  Future<bool> requestAlarmPermission() async {
    try {
      await _platform.invokeMethod('requestAlarmPermission');
      return true;
    } catch (e) {
      return false;
    }
  }

  // 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      await _platform.invokeMethod('requestNotificationPermission');
      return true;
    } catch (e) {
      return false;
    }
  }

  /* ---------- 通知权限建议状态 ---------- */
  bool get notificationAlreadySuggested {
    return _permissionState['notification_suggested'] ?? false;
  }

  Future<void> markNotificationSuggested() async {
    _permissionState['notification_suggested'] = true;
    await _savePermissionState();
  }

  /* ---------- 应用启动权限检查 ---------- */
  Future<void> checkAndSuggestPermissions(BuildContext context) async {
    // 检查精确闹钟权限
    final hasAlarmPermission = await checkAlarmPermission();
    if (!hasAlarmPermission) {
      await _showAlarmPermissionDialog(context);
    }

    // 检查通知权限（可选提醒）
    final hasNotificationPermission = await checkNotificationPermission();
    if (!hasNotificationPermission && !notificationAlreadySuggested) {
      await _showNotificationPermissionSuggestion(context);
    }
  }

  /* ---------- 权限对话框 ---------- */
  // 精确闹钟权限对话框
  Future<void> _showAlarmPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要精确闹钟权限'),
        content: const Text('定时关机功能需要精确闹钟权限来确保准时执行任务'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('去设置'),
          ),
        ],
      ),
    );

    if (result == true) {
      await requestAlarmPermission();
    }
  }

  // 通知权限建议对话框
  Future<void> _showNotificationPermissionSuggestion(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开启通知权限'),
        content: const Text('开启通知权限可以让您更好地接收任务执行状态提醒'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('不再提醒'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('去设置'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('忽略'),
          ),
        ],
      ),
    );

    switch (result) {
      case 0: // 不再提醒
        await markNotificationSuggested();
        break;
      case 1: // 去设置
        await requestNotificationPermission();
        await markNotificationSuggested();
        break;
      case 2: // 忽略
        await markNotificationSuggested();
        break;
    }
  }

  /* ---------- 任务相关的权限检查 ---------- */
  Future<bool> checkTaskPermission(BuildContext context) async {
    final hasPermission = await checkAlarmPermission();
    
    if (!hasPermission) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('需要精确闹钟权限'),
          content: const Text('开启定时任务需要精确闹钟权限'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('去设置'),
            ),
          ],
        ),
      ) ?? false;

      if (shouldRequest) {
        await requestAlarmPermission();
        // 从设置返回后重新检查
        await Future.delayed(const Duration(milliseconds: 300));
        return await checkAlarmPermission();
      }
      return false;
    }
    
    return true;
  }
}