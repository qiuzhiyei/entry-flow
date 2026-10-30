import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

Future<void> showDataBackupSheet(BuildContext context) {
  final provider = context.read<LedgerProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (sheetContext) => _DataBackupSheet(provider: provider),
  );
}

enum _ImportMode { merge, replace }

class _DataBackupSheet extends StatelessWidget {
  const _DataBackupSheet({required this.provider});

  final LedgerProvider provider;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x80091812),
            offset: Offset(0, -12),
            blurRadius: 32,
            spreadRadius: -18,
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE4DF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                '数据备份',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '导出到本地文件，或从备份文件导入',
                style: TextStyle(fontSize: 11.5, color: AppColors.ink3),
              ),
              const SizedBox(height: 12),
              _BackupAction(
                icon: Icons.save_alt_rounded,
                title: '导出备份',
                subtitle: '选择本地目录保存 JSON 备份',
                onTap: () => _export(context),
              ),
              const _RowDivider(),
              _BackupAction(
                icon: Icons.file_open_outlined,
                title: '导入备份',
                subtitle: '选择本地 .json 备份文件',
                onTap: () => _import(context),
              ),
              if (provider.lastBackupAt != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  Dates.backupLabel(provider.lastBackupAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                '导入时可选择合并（保留现有记录）或覆盖（清空后恢复）。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: Material(
                  color: const Color(0xFFF1F5F1),
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Center(
                      child: Text(
                        '完成',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final json = provider.buildBackupJson();
    final fileName = provider.backupFileName;

    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: '导出备份',
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
      );
      if (uri == null) return;

      await provider.markBackupExported(json);
      if (!context.mounted) return;
      showAppToast('备份已导出到本地文件');
    } catch (_) {
      if (context.mounted) showAppToast('导出失败，请重试');
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: '选择记账本备份',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      String source;
      try {
        source = utf8.decode(bytes);
      } on FormatException {
        throw const FormatException('备份文件格式不正确');
      }
      final preview = provider.parseBackup(source);
      if (preview.records.isEmpty) {
        if (context.mounted) showAppToast('备份中没有可导入的记录');
        return;
      }
      if (!context.mounted) return;

      final mode = await _askImportMode(context, preview);
      if (mode == null || !context.mounted) return;

      final summary = await provider.importBackup(
        source,
        replace: mode == _ImportMode.replace,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showAppToast('已导入 ${summary.imported} 条记录');
    } on FormatException catch (error) {
      if (context.mounted) {
        showAppToast(error.message.isEmpty ? '备份文件格式不正确' : error.message);
      }
    } catch (_) {
      if (context.mounted) showAppToast('导入失败，请检查文件后重试');
    }
  }

  Future<_ImportMode?> _askImportMode(
    BuildContext context,
    BackupPreview preview,
  ) {
    return showDialog<_ImportMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入备份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '共 ${preview.records.length} 条记录'
                '（日常 ${preview.dailyCount} · 旅行 ${preview.travelCount}）',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
              if (preview.exportedAt != null)
                Text(
                  '备份时间：${Dates.slashDate(preview.exportedAt!)} '
                  '${_time(preview.exportedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.ink3,
                  ),
                ),
              if (preview.skipped > 0)
                Text(
                  '有 ${preview.skipped} 条格式不正确的记录会被跳过。',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.danger,
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                '合并导入：保留现有记录，按 ID 覆盖重复项。\n'
                '覆盖导入：先清空当前所有记录，再恢复备份。',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink2,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ImportMode.replace),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('覆盖导入'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ImportMode.merge),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('合并导入'),
            ),
          ],
        );
      },
    );
  }

  static String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _BackupAction extends StatelessWidget {
  const _BackupAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.mintTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: AppColors.mintInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.chevron,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.line2);
  }
}
