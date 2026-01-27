import 'package:flutter/material.dart';
import 'package:hibiscus/src/rust/api/sync.dart' as sync_api;
import 'package:hibiscus/src/ui/pages/webdav_settings_page.dart';

class WebDavSyncService {
  static Future<void>? _inFlight;
  static bool _decryptDialogShown = false;
  static bool _startSyncTriggered = false;

  static Future<void> autoSyncOnAppStart({BuildContext? context}) async {
    if (_startSyncTriggered) return;
    _startSyncTriggered = true;
    final safeContext = context;
    final settings = await sync_api.getWebdavSettings();
    if (safeContext != null && !safeContext.mounted) return;
    if (!settings.autoSyncOnStart) return;
    await _syncOnce(context: safeContext, checkInterval: false);
  }

  static Future<void> autoSyncIfNeeded({BuildContext? context}) async {
    await _syncOnce(context: context, checkInterval: true);
  }

  static Future<void> _syncOnce({
    required bool checkInterval,
    BuildContext? context,
  }) async {
    if (_inFlight != null) return _inFlight!;

    final task = () async {
      if (checkInterval) {
        final should = await sync_api.shouldAutoSync();
        if (!should) return;
      }

      final result = await sync_api.syncHistory(forceUpload: false);

      if (result is sync_api.ApiSyncStatus_Success) {
        await sync_api.updateLastSyncTime();
        return;
      }

      if (result is sync_api.ApiSyncStatus_DecryptionFailed) {
        if (context == null) return;
        if (!context.mounted) return;
        if (_decryptDialogShown) return;
        _decryptDialogShown = true;
        await _showDecryptionFailedDialog(context);
      }
    }();

    _inFlight = task;
    try {
      await task;
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> _showDecryptionFailedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('无法解密云端数据'),
        content: const Text(
          '云端浏览记录无法使用当前密钥解密。\n\n'
          '你可以稍后同步（修改密钥），或强制用本地覆盖云端。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后同步'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WebDavSettingsPage()),
              );
            },
            child: const Text('修改密钥'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmAndForceUpload(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('强制覆盖云端'),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmAndForceUpload(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认强制覆盖'),
        content: const Text(
          '这将使用本地数据完全覆盖云端数据。\n\n'
          '云端的所有现有记录将被替换，此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认覆盖'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final result = await sync_api.forceUploadHistory();
    if (!context.mounted) return;

    if (result is sync_api.ApiSyncStatus_Success) {
      await sync_api.updateLastSyncTime();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已强制上传到云端'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result is sync_api.ApiSyncStatus_NetworkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传失败: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
