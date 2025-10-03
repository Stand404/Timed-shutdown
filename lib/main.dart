import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/header_tile.dart';
import 'widgets/task_list.dart';
import 'models/card_model.dart';
import 'utils/permission_manager.dart';

void main() => runApp(
    ChangeNotifierProvider(
        create: (_) => CardModel(),
        child: const MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '定时关机',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: const Color.fromARGB(255, 84, 161, 255)
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PermissionManager _permissionManager = PermissionManager();

  @override
  void initState() {
    super.initState();
    // 初始化权限管理器
    _permissionManager.initialize().then((_) {
      // 应用启动时检查权限
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _permissionManager.checkAndSuggestPermissions(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: const [
            HeaderTile(),      // 固定标题
            Expanded(child: TaskList()), // 可滚动列表
          ],
        ),
      ),
    );
  }
}