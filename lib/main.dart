import 'package:flutter/material.dart';
import './src/index.dart';
import './src/sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import './src/home/home_index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (_) => BoxDataNotifier(),
      child:  MaterialApp(
        // 关键返回箭头更改
        theme:  ThemeData(
          appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(
              color: Color.fromARGB(255, 102, 102, 102), // 设置全局返回箭头颜色
              size: 22,          // 设置全局返回箭头大小
            ),
          ),
        ),
        home: const Home(),
      ),
    );
  }
}