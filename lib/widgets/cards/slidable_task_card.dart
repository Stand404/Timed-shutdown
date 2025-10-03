import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../models/card_item.dart';
import '../../models/card_model.dart';
import '../dialogs/app_snack.dart';
import '../dialogs/task_dialog.dart';

class SlidableTaskCard extends StatefulWidget {
  final CardItem item;
  const SlidableTaskCard({super.key, required this.item});

  @override
  State<SlidableTaskCard> createState() => _SlidableTaskCardState();
}

class _SlidableTaskCardState extends State<SlidableTaskCard>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false; // 动画开关

  Future<void> _animateDelete() async {
    setState(() => _isDeleting = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    // 真正删除
    try {
    await context.read<CardModel>().delete(widget.item.id);
      if (!mounted) return;          // 页面已卸载，直接返回
      showAppSnack(context, '已删除 ${widget.item.note}');
    } on PlatformException catch (e){
      showAppSnack(context, e.message??"任务删除失败");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            CustomSlidableAction(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onPressed: (_) => showTaskDialog(context, item: widget.item),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.edit, size: 20), Text('编辑')],
              ),
            ),
            CustomSlidableAction(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              onPressed: (_) {
                Slidable.of(context)?.close(); // 先收回滑块
                _animateDelete();              // 再播放动画删除
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.delete, size: 20), Text('删除')],
              ),
            ),
          ],
        ),
        child: AnimatedScale(
          scale: _isDeleting ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          child: AnimatedOpacity(
            opacity: _isDeleting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.item.time,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(widget.item.note,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.item.enabled,
                      onChanged: (_) async {
                        try{
                          await context.read<CardModel>().toggle(widget.item.id, context);
                        }on PlatformException catch (e){
                          if(!mounted) return;
                          // ignore: use_build_context_synchronously
                          showAppSnack(context, e.message??"任务设置失败");
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}