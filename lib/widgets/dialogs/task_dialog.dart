import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/card_item.dart';
import '../../models/card_model.dart';
import 'app_snack.dart';

Future<void> showTaskDialog(BuildContext context, {CardItem? item}) async {
  final isEdit = item != null;
  final model = context.read<CardModel>();

  TimeOfDay initialTime;
  try {
    final parts = (isEdit ? item.time : '00:00').split(':'); // 只留 HH:mm
    initialTime = TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  } catch (_) {
    initialTime = const TimeOfDay(hour: 0, minute: 0);
  }

  final timeCtrl = TextEditingController(text: isEdit ? item.time : '00:00');
  final noteCtrl = TextEditingController(text: isEdit ? item.note : '');

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(isEdit ? '编辑任务' : '新增任务'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: timeCtrl,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: '时间（HH:mm）',
              suffixIcon: Icon(Icons.access_time),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
                builder: (_, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) {
                timeCtrl.text =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: '备注'),
            autofocus: !isEdit,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async{
            if (timeCtrl.text.isEmpty || noteCtrl.text.trim().isEmpty) return;
            final navigator = Navigator.of(context);
            try{
              isEdit
                ? await model.edit(item.id, timeCtrl.text, noteCtrl.text.trim())
                : await model.add(timeCtrl.text, noteCtrl.text.trim());
              navigator.pop();
            }on PlatformException catch (e){
              showAppSnack(context, e.message??"任务设置失败");
            }
          },
          child: Text(isEdit ? '保存' : '添加'),
        ),
      ],
    ),
  );
}