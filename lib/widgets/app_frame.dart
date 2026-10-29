import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps the mobile composition intact on tablet/desktop by centering the
/// ledger on a soft stage. Phones get the full-bleed, native layout.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  static const double _frameWidth = 430;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return child;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.72),
              radius: 1.05,
              colors: <Color>[Color(0xFFFDFEFD), AppColors.stage],
              stops: <double>[0, 1],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                width: _frameWidth,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33181C1F),
                      offset: Offset(0, 30),
                      blurRadius: 64,
                      spreadRadius: -18,
                    ),
                    BoxShadow(
                      color: Color(0x1F181C1F),
                      offset: Offset(0, 8),
                      blurRadius: 20,
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(
                      _frameWidth,
                      constraints.maxHeight > 48
                          ? constraints.maxHeight - 48
                          : constraints.maxHeight,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
