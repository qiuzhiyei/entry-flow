import 'package:hive_flutter/hive_flutter.dart';

import '../models/record.dart';

/// Sets up Hive and exposes the app's boxes.
abstract final class HiveService {
  static const String recordsBoxName = 'records';
  static const String metaBoxName = 'meta';
  static const String _subDirectory = 'mint_ledger';

  static late Box<Record> recordsBox;

  /// Small app-level flags (for example whether demo data was already seeded).
  static late Box<dynamic> metaBox;

  static Future<void> init() async {
    await Hive.initFlutter(_subDirectory);
    if (!Hive.isAdapterRegistered(Record.hiveTypeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
    recordsBox = await Hive.openBox<Record>(recordsBoxName);
    metaBox = await Hive.openBox<dynamic>(metaBoxName);
  }

  static Future<void> close() => Hive.close();
}
