/// A local ledger. The app intentionally keeps a single daily ledger; the
/// type is retained so old backup files and records remain readable.
class Ledger {
  const Ledger({required this.id, required this.name});

  final String id;
  final String name;
}

abstract final class Ledgers {
  static const Ledger daily = Ledger(id: 'daily', name: '日常账本');

  static const List<Ledger> all = <Ledger>[daily];

  static Ledger byId(String? id) => daily;
}
