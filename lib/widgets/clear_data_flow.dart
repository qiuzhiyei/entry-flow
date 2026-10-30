import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';

/// Destructive clear flow: two confirmations, with the final action locked for
/// three seconds so it cannot be triggered by a double tap or muscle memory.
Future<void> showClearDataFlow(BuildContext context) async {
  final provider = context.read<LedgerProvider>();
  final count = provider.allRecords.length;
  if (count == 0) {
    showAppToast('当前没有可清理的账目');
    return;
  }

  final first = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('清理全部数据？'),
        content: const Text(
          '将永久删除全部账目，且无法恢复。\n\n'
          '建议先在「数据备份」里导出一份 JSON 备份；已经导出到本地的备份文件不会被删除。',
          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.ink2),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        actions: <Widget>[
          SizedBox(
            width: 104,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
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
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('继续'),
            ),
          ),
        ],
      );
    },
  );
  if (first != true || !context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _FinalClearDialog(count: count);
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await provider.clearAll();
    if (!context.mounted) return;
    showAppToast('已清理全部账目');
  } catch (_) {
    if (!context.mounted) return;
    showAppToast('清理失败，请重试');
  }
}

class _FinalClearDialog extends StatefulWidget {
  const _FinalClearDialog({required this.count});

  final int count;

  @override
  State<_FinalClearDialog> createState() => _FinalClearDialogState();
}

class _FinalClearDialogState extends State<_FinalClearDialog> {
  static const int _waitSeconds = 3;
  int _remaining = _waitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _remaining == 0;
    return AlertDialog(
      title: const Text('再次确认'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '将永久删除全部 ${widget.count} 条账目。\n\n此操作不可撤销。',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: ready ? AppColors.mintSoft : AppColors.mintTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    ready
                        ? Icons.check_circle_outline_rounded
                        : Icons.timer_outlined,
                    size: 16,
                    color: ready ? AppColors.mint : AppColors.ink3,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ready ? '现在可以确认清理' : '请等待 $_remaining 秒',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: ready ? AppColors.mintInk : AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      actions: <Widget>[
        SizedBox(
          width: 116,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink2,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('取消'),
          ),
        ),
        SizedBox(
          width: 116,
          height: 44,
          child: FilledButton(
            onPressed: ready ? () => Navigator.of(context).pop(true) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE7ECE8),
              disabledForegroundColor: AppColors.ink3,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('确认清理'),
          ),
        ),
      ],
    );
  }
}
