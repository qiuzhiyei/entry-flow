import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Future<int?> showBudgetEditDialog(
  BuildContext context, {
  required int currentCents,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _BudgetEditDialog(currentCents: currentCents),
  );
}

class _BudgetEditDialog extends StatefulWidget {
  const _BudgetEditDialog({required this.currentCents});

  final int currentCents;

  @override
  State<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<_BudgetEditDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentCents / 100).round().toString(),
    );
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final yuan = int.tryParse(_controller.text.trim());
    if (yuan == null || yuan <= 0) {
      setState(() => _error = '请输入大于 0 的金额');
      return;
    }
    if (yuan > 9999999) {
      setState(() => _error = '预算不能超过 ¥9,999,999');
      return;
    }
    Navigator.of(context).pop(yuan * 100);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置本月预算'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '预算只影响本月进度展示，不会修改任何账目。',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
            style: const TextStyle(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              prefixText: '¥ ',
              suffixText: '元',
              hintText: '5000',
              errorText: _error,
              filled: true,
              fillColor: AppColors.mintTint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.mintBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.mint, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '默认预算 ¥5,000，可随时修改。',
            style: TextStyle(fontSize: 11.5, color: AppColors.ink3),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      actions: <Widget>[
        SizedBox(
          width: 104,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink2,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('取消'),
          ),
        ),
        SizedBox(
          width: 104,
          height: 44,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mint,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }
}
