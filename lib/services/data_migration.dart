import 'package:hive/hive.dart';

import '../models/record.dart';

/// One-time cleanup for installs created by older demo builds. New installs
/// start with an empty ledger; no sample records are ever added.
abstract final class DataMigration {
  static const String _dailyLedger = 'daily';
  static const String _cleanupKey = 'clean_ledger_v1';

  static Future<void> migrate(Box<Record> box, Box<dynamic> metaBox) async {
    if (metaBox.get(_cleanupKey) == true) return;

    final entries = box.toMap().entries.toList(growable: false);
    for (final entry in entries) {
      final record = entry.value;
      if (record.id.startsWith('demo-')) {
        await box.delete(entry.key);
      } else if (record.ledgerId != _dailyLedger) {
        await box.put(entry.key, record.copyWith(ledgerId: _dailyLedger));
      }
    }

    await metaBox.put(_cleanupKey, true);
    await metaBox.put('selected_ledger', _dailyLedger);
    await metaBox.delete('demo_seeded');
    await metaBox.delete('demo_version');
  }
}
