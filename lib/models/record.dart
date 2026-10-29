import 'package:hive/hive.dart';

/// Whether a record increases or decreases the balance.
enum RecordType {
  expense,
  income;

  bool get isExpense => this == RecordType.expense;

  String get label => this == RecordType.expense ? '支出' : '收入';
}

/// A single ledger entry.
///
/// Money is stored as integer cents so repeated addition never drifts.
/// Dates are persisted as local ISO-8601 strings: a ledger day is a calendar
/// day, not a UTC instant, so it must not shift when the timezone changes.
class Record {
  const Record({
    required this.id,
    required this.amountCents,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final int amountCents;
  final RecordType type;
  final String categoryId;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  static const int hiveTypeId = 0;

  double get amount => amountCents / 100;

  Record copyWith({
    String? id,
    int? amountCents,
    RecordType? type,
    String? categoryId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return Record(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Record(id: $id, type: ${type.name}, amountCents: $amountCents, '
        'categoryId: $categoryId, date: $date, note: $note)';
  }
}

class RecordAdapter extends TypeAdapter<Record> {
  @override
  int get typeId => Record.hiveTypeId;

  @override
  Record read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Record(
      id: fields[0] as String,
      amountCents: fields[1] as int,
      type: RecordType.values[(fields[2] as int).clamp(0, 1).toInt()],
      categoryId: fields[3] as String,
      date: _readDate(fields[4]),
      note: (fields[5] as String?) ?? '',
      createdAt: _readDate(fields[6]),
    );
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amountCents)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.date.toIso8601String())
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt.toIso8601String());
  }

  static DateTime _readDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }
}
