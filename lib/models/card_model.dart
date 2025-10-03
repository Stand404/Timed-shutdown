import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'card_item.dart';
import '../utils/permission_manager.dart';

class CardModel extends ChangeNotifier {
  List<CardItem> _list = [];
  List<CardItem> get list => _list;
  
  final PermissionManager _permissionManager = PermissionManager();

  CardModel() {
    _load();
  }

  /* ---------- 任务文件 I/O ---------- */
  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tasks.json');
  }

  Future<void> _load() async {
    final file = await _localFile;
    if (!await file.exists()) return;
    final raw = await file.readAsString();
    final List<dynamic> decoded = jsonDecode(raw);
    _list = decoded.map((e) => CardItem.fromJson(e)).toList();
    notifyListeners();
    // 重投闹钟
    for (final item in _list.where((e) => e.enabled)) {
      await _setAlarm(item);
    }
  }

  Future<void> _save() async {
    final file = await _localFile;
    final encoded = jsonEncode(_list.map((e) => e.toJson()).toList());
    await file.writeAsString(encoded);
  }

  /* ---------- 原生层通信 ---------- */
  Future<void> _setAlarm(CardItem item) async {
    const platform = MethodChannel('auto_shutdown');
    await platform.invokeMethod('enable', {
      'taskId': item.id,
      'time': item.time,
    });
  }

  Future<void> _cancelAlarm(CardItem item) async {
    const platform = MethodChannel('auto_shutdown');
    await platform.invokeMethod('disable', {'taskId': item.id});
  }

  /* ---------- 业务方法 ---------- */
  Future<void> add(String time, String note) async {
    final newItem = CardItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: time,
      note: note,
      enabled: false,
    );
    _list.add(newItem);
    notifyListeners();
    await _save();
  }

  Future<void> edit(String id, String time, String note) async {
    final i = _list.indexWhere((e) => e.id == id);
    if (i == -1) return;

    if (_list[i].enabled) await _cancelAlarm(_list[i]);

    _list[i].time = time;
    _list[i].note = note;
    notifyListeners();
    await _save();

    if (_list[i].enabled) await _setAlarm(_list[i]);
  }

  Future<void> delete(String id) async {
    final item = _list.firstWhere((e) => e.id == id);
    if (item.enabled) await _cancelAlarm(item);
    _list.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  /* ---------- 开关任务 ---------- */
  Future<void> toggle(String id, BuildContext context) async {
    final i = _list.indexWhere((e) => e.id == id);
    if (i == -1) return;

    final nowEnabled = !_list[i].enabled;
    
    if (nowEnabled) {
      try {
        // 使用 PermissionManager 检查权限
        final hasPermission = await _permissionManager.checkTaskPermission(context);
        
        if (hasPermission) {
          await _setAlarm(_list[i]);
          _list[i].enabled = true;
          notifyListeners();
          await _save();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开启任务失败: $e')),
        );
      }
    } else {
      try {
        await _cancelAlarm(_list[i]);
        _list[i].enabled = false;
      } catch (e) {
        _list[i].enabled = false;
      }
      notifyListeners();
      await _save();
    }
  }
}