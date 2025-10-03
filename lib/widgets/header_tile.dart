import 'package:flutter/material.dart';
import 'package:root_checker_plus/root_checker_plus.dart';
import './dialogs/about_dialog.dart'; 

class HeaderTile extends StatefulWidget {
  const HeaderTile({super.key});

  @override
  State<HeaderTile> createState() => _HeaderTileState();
}

class _HeaderTileState extends State<HeaderTile> {
  bool rootedCheck = false;

  @override
  void initState() {
    super.initState();
    _checkRoot();
  }

  Future<void> _checkRoot() async {
    final isRoot = await RootCheckerPlus.isRootChecker() ?? false;
    if (mounted) {
      setState(() => rootedCheck = isRoot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(
                  text: '任务列表',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                WidgetSpan(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Icon(
                      rootedCheck ? Icons.check_circle : Icons.highlight_off,
                      color: rootedCheck ? Colors.green : Colors.red,
                      size: 15,
                    ),
                  ),
                ),
                TextSpan(
                  text: rootedCheck ? '已Root' : '未Root',
                  style: TextStyle(
                    fontSize: 13,
                    color: rootedCheck ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.help_outline, size: 22),
            onPressed: () => showAboutAppDialog(context),
          ),
        ],
      ),
    );
  }
}