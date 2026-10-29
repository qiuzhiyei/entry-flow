import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// A single app-wide toast, matching the prototype's compact dark pill.
final ValueNotifier<String?> _appToast = ValueNotifier<String?>(null);
Timer? _toastTimer;

void showAppToast(String message) {
  _toastTimer?.cancel();
  _appToast.value = message;
  _toastTimer = Timer(const Duration(seconds: 2), () {
    _appToast.value = null;
  });
}

/// Sits above the Navigator so toasts also show over full-screen routes and
/// modal sheets, just like the prototype's overlay.
class AppToastHost extends StatelessWidget {
  const AppToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + 88,
          child: IgnorePointer(
            child: Center(
              child: ValueListenableBuilder<String?>(
                valueListenable: _appToast,
                builder: (context, message, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: AppMotion.ease,
                    switchOutCurve: AppMotion.ease,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: message == null
                        ? const SizedBox.shrink(key: ValueKey<String>('empty'))
                        : Container(
                            key: ValueKey<String>(message),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width - 40,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
