import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../models/category.dart';
import '../models/record.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocus = FocusNode();

  RecordType _type = RecordType.expense;
  String _categoryId = 'food';
  String _raw = '0';
  DateTime _date = Dates.dayOnly(DateTime.now());
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteFocus.addListener(_handleNoteFocusChanged);
  }

  @override
  void dispose() {
    _noteFocus
      ..removeListener(_handleNoteFocusChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleNoteFocusChanged() {
    if (mounted) setState(() {});
  }

  int get _amountCents {
    final parts = _raw.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    if (parts.length == 1) return whole * 100;
    final fraction = parts[1].padRight(2, '0').substring(0, 2);
    return whole * 100 + (int.tryParse(fraction) ?? 0);
  }

  void _appendKey(String key) {
    setState(() {
      _error = null;
      if (key == '.') {
        if (!_raw.contains('.')) _raw = '$_raw.';
        return;
      }
      if (_raw == '0') {
        _raw = key;
        return;
      }
      final parts = _raw.split('.');
      if (parts.length > 1 && parts[1].length >= 2) return;
      if (parts.length == 1 && parts[0].length >= 7) return;
      _raw = '$_raw$key';
    });
  }

  void _backspace() {
    setState(() {
      _error = null;
      if (_raw.length <= 1) {
        _raw = '0';
      } else {
        _raw = _raw.substring(0, _raw.length - 1);
        if (_raw.isEmpty || _raw == '-') _raw = '0';
      }
    });
  }

  void _clear() {
    setState(() {
      _raw = '0';
      _error = null;
    });
  }

  void _selectType(RecordType type) {
    if (_type == type) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _type = type;
      _categoryId = LedgerCategories.forType(type).first.id;
      _error = null;
    });
  }

  void _selectCategory(String id) {
    FocusScope.of(context).unfocus();
    setState(() {
      _categoryId = id;
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _date = Dates.dayOnly(picked));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final cents = _amountCents;
    if (cents <= 0) {
      setState(() => _error = '请输入大于 0 的金额');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final now = DateTime.now();
    final occurredAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      now.hour,
      now.minute,
    );
    final category = LedgerCategories.byId(_categoryId, type: _type);

    try {
      await context.read<LedgerProvider>().addRecord(
        amountCents: cents,
        type: _type,
        categoryId: _categoryId,
        date: occurredAt,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast('已记录 · ${category.name} ${Money.formatCents(cents)}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '保存失败，请重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardVisible = _noteFocus.hasFocus;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(onBack: () => Navigator.of(context).maybePop()),
            _TypeSegment(value: _type, onChanged: _selectType),
            _AmountDisplay(type: _type, raw: _raw),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                child: Text(_error!, style: AppText.error),
              ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _CategoryGrid(
                      type: _type,
                      selectedId: _categoryId,
                      onSelected: _selectCategory,
                    ),
                    _DetailCard(
                      date: _date,
                      noteController: _noteController,
                      noteFocus: _noteFocus,
                      onPickDate: _pickDate,
                    ),
                  ],
                ),
              ),
            ),
            if (!keyboardVisible)
              _Keypad(
                bottomInset: bottomInset,
                onKey: _appendKey,
                onBackspace: _backspace,
                onClear: _clear,
                onSave: _save,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                tooltip: '返回',
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  maximumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.chevron_left_rounded, size: 26),
              ),
            ),
            const Text(
              '记一笔',
              style: TextStyle(
                fontSize: 19,
                height: 1.2,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.19,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.value, required this.onChanged});

  final RecordType value;
  final ValueChanged<RecordType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentBg,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        children: <Widget>[
          for (final type in RecordType.values)
            Expanded(
              child: _SegmentButton(
                label: type.label,
                selected: value == type,
                selectedColor: type == RecordType.income
                    ? AppColors.amberInk
                    : AppColors.ink,
                onTap: () => onChanged(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: AppMotion.ease,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x2112211B),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: selected ? selectedColor : AppColors.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.type, required this.raw});

  final RecordType type;
  final String raw;

  @override
  Widget build(BuildContext context) {
    final isIncome = type == RecordType.income;
    final color = isIncome ? AppColors.amberInk : AppColors.ink;
    final currencyColor = isIncome ? AppColors.amberInk : AppColors.ink3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '¥',
              style: TextStyle(
                fontSize: 21,
                height: 1,
                fontWeight: FontWeight.w600,
                color: currencyColor,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Money.formatInput(raw),
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.4,
                  color: color,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 2),
          const _BlinkingCaret(),
        ],
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: _controller.value < 0.5 ? 1 : 0, child: child);
      },
      child: Container(
        width: 2,
        height: 30,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.type,
    required this.selectedId,
    required this.onSelected,
  });

  final RecordType type;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = LedgerCategories.forType(type);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        mainAxisExtent: 72,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final selected = category.id == selectedId;
        return _CategoryTile(
          category: category,
          selected: selected,
          onTap: () => onSelected(category.id),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final LedgerCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.background,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected ? category.foreground : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(color: category.ring, spreadRadius: 3),
                        ]
                      : null,
                ),
                child: Icon(
                  category.icon,
                  size: 22,
                  color: category.foreground,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                category.name,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.date,
    required this.noteController,
    required this.noteFocus,
    required this.onPickDate,
  });

  final DateTime date;
  final TextEditingController noteController;
  final FocusNode noteFocus;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.soft),
        border: Border.all(color: AppColors.line2),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 38,
                  child: Text(
                    '日期',
                    style: TextStyle(fontSize: 13, color: AppColors.ink2),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            Dates.slashDate(date),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.ink,
                              fontFeatures: <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.ink3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.line2),
          SizedBox(
            height: 48,
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 38,
                  child: Text(
                    '备注',
                    style: TextStyle(fontSize: 13, color: AppColors.ink2),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: noteController,
                    focusNode: noteFocus,
                    textAlign: TextAlign.right,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 1,
                    maxLength: 20,
                    cursorColor: AppColors.mint,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '写下这笔钱的用途',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.hint,
                      ),
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.bottomInset,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onSave,
  });

  final double bottomInset;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSave;

  static const double _gap = 8;
  static const double _keyHeight = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyWidth = (constraints.maxWidth - _gap * 3) / 4;

          return SizedBox(
            height: _keyHeight * 4 + _gap * 3,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: _keyHeight,
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _numberKey('1')),
                      const SizedBox(width: _gap),
                      Expanded(child: _numberKey('2')),
                      const SizedBox(width: _gap),
                      Expanded(child: _numberKey('3')),
                      const SizedBox(width: _gap),
                      Expanded(
                        child: _KeyButton(
                          onTap: onBackspace,
                          background: Colors.transparent,
                          child: const Icon(
                            Icons.backspace_outlined,
                            size: 22,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _gap),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Expanded(child: _rowOf(<String>['4', '5', '6'])),
                            const SizedBox(height: _gap),
                            Expanded(child: _rowOf(<String>['7', '8', '9'])),
                            const SizedBox(height: _gap),
                            Expanded(child: _rowOf(<String>['.', '0', '清空'])),
                          ],
                        ),
                      ),
                      const SizedBox(width: _gap),
                      SizedBox(
                        width: keyWidth,
                        child: _KeyButton(
                          onTap: onSave,
                          radius: AppRadii.key,
                          background: AppColors.mint,
                          child: const Text(
                            '完成',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rowOf(List<String> keys) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < keys.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(
            child: keys[i] == '清空'
                ? _KeyButton(
                    onTap: onClear,
                    background: Colors.transparent,
                    child: const Text(
                      '清空',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink3,
                      ),
                    ),
                  )
                : _numberKey(keys[i]),
          ),
        ],
      ],
    );
  }

  Widget _numberKey(String value) {
    return _KeyButton(
      onTap: () => onKey(value),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          height: 1,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.onTap,
    required this.child,
    this.background = AppColors.keyBg,
    this.radius = AppRadii.key,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color background;
  final double radius;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.955 : 1,
      duration: const Duration(milliseconds: 100),
      curve: AppMotion.ease,
      child: Material(
        color: widget.background,
        borderRadius: BorderRadius.circular(widget.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            if (_pressed != value) setState(() => _pressed = value);
          },
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
