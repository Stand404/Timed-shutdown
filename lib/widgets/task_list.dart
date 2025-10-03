import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import 'cards/add_button_card.dart';
import 'cards/slidable_task_card.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CardModel>();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: model.list.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) return const AddButtonCard();
        final item = model.list[index - 1];
        return SlidableTaskCard(item: item);
      },
    );
  }
}