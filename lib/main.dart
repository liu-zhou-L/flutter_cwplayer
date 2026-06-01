import 'package:flutter/material.dart';
import 'widgets/cw_player.dart';
import 'theme/steampunk_theme.dart';

void main() => runApp(const CWApp());

class CWApp extends StatelessWidget {
  const CWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CW Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SteampunkTheme.bgDark,
        primaryColor: SteampunkTheme.brass,
        colorScheme: const ColorScheme.dark(
          primary: SteampunkTheme.brass,
          secondary: SteampunkTheme.copper,
          surface: SteampunkTheme.bgMedium,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: SteampunkTheme.bgMedium,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: SteampunkTheme.brass,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('⚙ 莫尔斯电码练习器 ⚙')),
        body: const SafeArea(child: CWPlayer()),
      ),
    );
  }
}
