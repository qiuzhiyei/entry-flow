import 'package:flutter/material.dart';

/// Root messenger so screens can show the prototype-style toast after they
/// have already been popped.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(String message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      ),
    );
}
