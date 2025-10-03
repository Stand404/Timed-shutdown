import 'package:flutter/material.dart';

/// 统一圆角浮动提示
void showAppSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(          // ← 让文字居中
        child: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
      backgroundColor: Theme.of(context).colorScheme.primary
    ),
  );
}