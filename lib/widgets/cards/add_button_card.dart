import 'package:flutter/material.dart';
import '../dialogs/task_dialog.dart';

class AddButtonCard extends StatelessWidget {
  const AddButtonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary; // 运行时取主题色
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showTaskDialog(context),
        child: SizedBox(
          height: 72,
          child: Center(
            child: Icon(Icons.add, size: 32, color: color), 
          ),
        ),
      ),
    );
  }
}