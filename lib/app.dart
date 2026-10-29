import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_keys.dart';
import 'screens/add_record_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_frame.dart';
import 'widgets/bottom_nav.dart';

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账本',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const <Locale>[Locale('zh', 'CN')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: appMessengerKey,
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.surface,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: AppFrame(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const LedgerShell(),
    );
  }
}

class LedgerShell extends StatefulWidget {
  const LedgerShell({super.key});

  @override
  State<LedgerShell> createState() => _LedgerShellState();
}

class _LedgerShellState extends State<LedgerShell> {
  int _tab = 0;

  Future<void> _openAdd() async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const AddRecordScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.ease,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.012),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: <Widget>[
                  HomeScreen(
                    onOpenStats: () => setState(() => _tab = 1),
                    onAdd: _openAdd,
                  ),
                  const StatsScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
            AppBottomNav(
              selectedIndex: _tab,
              onSelect: (index) => setState(() => _tab = index),
              onAdd: _openAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
