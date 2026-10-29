import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

/// Shown only when Hive cannot be opened, instead of leaving a blank screen.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppFrame(
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.storage_rounded,
                        size: 28,
                        color: AppColors.mintInk,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '本地账本加载失败',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '暂时无法读取本机的记账数据。请完全关闭应用后重新打开；如果问题仍然存在，请检查设备的存储空间。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.ink2,
                      ),
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
