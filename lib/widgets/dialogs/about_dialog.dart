import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_snack.dart';

/// 弹出“关于”模态框
void showAboutAppDialog(BuildContext context) {
  final color = Theme.of(context).colorScheme.primary;
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
      title: Text(
        '定时关机',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:color),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text(
            '任务左划可编辑和删除，启动后到点自动关机，仅支持Root使用\n注意事项：开启任务后，如果定时早于当前时间，第二天才会触发，若修改系统时间提前，则需要重新更新任务',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'CopyRight © 2025 Stand',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final uri = Uri.parse('https://space.bilibili.com/382365750');
              final open = await launchUrl(uri,mode: LaunchMode.externalApplication);
              if (!open) {
                showAppSnack(context, '无法打开链接');
              }
            },
            child: Text(
              'bilibili@Stand',
              style: TextStyle(
                color: color,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}