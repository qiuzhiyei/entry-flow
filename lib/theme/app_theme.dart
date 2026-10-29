import 'package:flutter/material.dart';

/// Design tokens extracted from `design_ref/.../index.html`.
abstract final class AppColors {
  static const canvas = Color(0xFFF3F6F2);
  static const stage = Color(0xFFEAEBEE);
  static const surface = Color(0xFFFFFFFF);

  static const line = Color(0xFFE6EBE6);
  static const line2 = Color(0xFFEFF3EF);

  static const ink = Color(0xFF12211B);
  static const ink2 = Color(0xFF57675F);
  static const ink3 = Color(0xFF6E7C76);

  static const mint = Color(0xFF0C7E60);
  static const mintInk = Color(0xFF0A6B51);
  static const mintDeep = Color(0xFF08543F);
  static const mintSoft = Color(0xFFE3F2EA);
  static const mintTint = Color(0xFFF1F8F4);
  static const mintBorder = Color(0xFFD2E9DE);

  static const amber = Color(0xFFD9651C);
  static const amberInk = Color(0xFFA8551A);
  static const amberSoft = Color(0xFFFCEFE2);

  static const danger = Color(0xFFB3372E);

  static const balanceLabel = Color(0xFF3A6A5A);
  static const balanceKey = Color(0xFF477364);
  static const balanceInk = Color(0xFF073A2B);

  static const segmentBg = Color(0xFFE8EFEA);
  static const keyBg = Color(0xFFF4F7F3);
  static const hint = Color(0xFF9BA7A1);
  static const chevron = Color(0xFFAFBAB4);

  static const onMint = Color(0xFFFFFFFF);
  static const balanceDivider = Color(0x1F073A2B);
  static const deltaPill = Color(0xC7FFFFFF);
  static const scrim = Color(0x6B091812);
}

abstract final class AppRadii {
  static const card = 20.0;
  static const list = 18.0;
  static const soft = 16.0;
  static const chip = 14.0;
  static const key = 13.0;
}

abstract final class AppSpacing {
  static const page = 20.0;
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x8C0F281E),
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -20,
    ),
    BoxShadow(
      color: Color(0x1F0F281E),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -5,
    ),
  ];

  static const fab = <BoxShadow>[
    BoxShadow(
      color: Color(0xBF0C7E60),
      offset: Offset(0, 16),
      blurRadius: 30,
      spreadRadius: -14,
    ),
    BoxShadow(
      color: Color(0x660C7E60),
      offset: Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];
}

abstract final class AppMotion {
  static const ease = Cubic(0.22, 0.61, 0.36, 1);
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 260);
}

/// System Chinese fonts, matching the prototype's font stack.
abstract final class AppFonts {
  static const fallback = <String>[
    'PingFang SC',
    'HarmonyOS Sans SC',
    'MiSans',
    'Noto Sans SC',
    'Source Han Sans SC',
    'Microsoft YaHei',
  ];
}

abstract final class AppText {
  static const eyebrow = TextStyle(
    fontSize: 11.5,
    height: 1.35,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.46,
    color: AppColors.ink3,
  );

  static const greeting = TextStyle(
    fontSize: 22,
    height: 1.24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.44,
    color: AppColors.ink,
  );

  static const screenTitle = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.44,
    color: AppColors.ink,
  );

  static const balanceLabel = TextStyle(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.balanceLabel,
  );

  static const balanceAmount = TextStyle(
    fontSize: 37,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.3,
    color: AppColors.balanceInk,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const balanceKey = TextStyle(
    fontSize: 11.5,
    height: 1.4,
    color: AppColors.balanceKey,
  );

  static const balanceValue = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.16,
    color: AppColors.balanceInk,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const sectionTitle = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: AppColors.ink,
  );

  static const link = TextStyle(
    fontSize: 12.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.mintInk,
  );

  static const dayLabel = TextStyle(
    fontSize: 11.5,
    height: 1.2,
    color: AppColors.ink3,
  );

  static const dayTotal = TextStyle(
    fontSize: 11,
    height: 1.2,
    color: AppColors.ink3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const recordName = TextStyle(
    fontSize: 14.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const recordNote = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: AppColors.ink3,
  );

  static const recordAmount = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: AppColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const navLabel = TextStyle(
    fontSize: 10.5,
    height: 1.1,
    fontWeight: FontWeight.w500,
    color: AppColors.ink3,
  );

  static const fabLabel = TextStyle(
    fontSize: 14,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    color: AppColors.onMint,
  );

  static const error = TextStyle(
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.danger,
  );
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.mint,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.mint,
          onPrimary: AppColors.onMint,
          secondary: AppColors.amberInk,
          onSecondary: AppColors.onMint,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.danger,
          onError: AppColors.onMint,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      fontFamilyFallback: AppFonts.fallback,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: const Color(0x140C7E60),
      hoverColor: const Color(0x0A12211B),
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      dividerTheme: const DividerThemeData(
        color: AppColors.line2,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.mint,
        selectionColor: AppColors.mintSoft,
        selectionHandleColor: AppColors.mint,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        headerBackgroundColor: AppColors.mintSoft,
        headerForegroundColor: AppColors.balanceInk,
        weekdayStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.ink3,
        ),
        dayStyle: const TextStyle(fontSize: 13.5, color: AppColors.ink),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.mint;
          if (states.contains(WidgetState.hovered)) return AppColors.mintTint;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) {
            return AppColors.ink3.withValues(alpha: 0.38);
          }
          return AppColors.ink;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.mintInk),
        todayBorder: const BorderSide(color: AppColors.mint, width: 1.2),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.ink;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.mint;
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.ink2,
          minimumSize: const Size(0, 44),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.mintInk,
          minimumSize: const Size(0, 44),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.18,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13.5,
          height: 1.55,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}
