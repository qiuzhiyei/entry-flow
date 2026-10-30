import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/ledger_provider.dart';
import 'services/hive_service.dart';
import 'services/data_migration.dart';
import 'screens/startup_failure_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveService.init();
    await DataMigration.migrate(HiveService.recordsBox, HiveService.metaBox);
  } catch (error, stackTrace) {
    debugPrint('Ledger startup failed: $error\n$stackTrace');
    runApp(const StartupFailureApp());
    return;
  }

  runApp(
    ChangeNotifierProvider<LedgerProvider>(
      create: (_) =>
          LedgerProvider(HiveService.recordsBox, HiveService.metaBox),
      child: const LedgerApp(),
    ),
  );
}
