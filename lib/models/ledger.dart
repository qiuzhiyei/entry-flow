/// A named ledger. The prototype ships with two ledgers and the selected one
/// is persisted, so switching really changes which records the screens show.
class Ledger {
  const Ledger({required this.id, required this.name});

  final String id;
  final String name;
}

abstract final class Ledgers {
  static const Ledger daily = Ledger(id: 'daily', name: '日常账本');
  static const Ledger travel = Ledger(id: 'travel', name: '旅行账本');

  static const List<Ledger> all = <Ledger>[daily, travel];

  static Ledger byId(String? id) {
    for (final ledger in all) {
      if (ledger.id == id) return ledger;
    }
    return daily;
  }
}
