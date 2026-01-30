import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hibiscus/src/services/app_logger.dart';
import 'package:hibiscus/src/services/rust_kv_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _lastUpdateCheckKey = 'update.last_check_ms';
const _nextUpdatePromptMsKey = 'update.next_prompt_ms';
const _ignoredLatestVersionKey = 'update.ignored_version';

const Duration _autoCheckInterval = Duration(hours: 12);
const Duration _promptOneDay = Duration(days: 1);
const Duration _promptOneWeek = Duration(days: 7);

const String updateOwner = String.fromEnvironment(
  'UPDATE_OWNER',
  defaultValue: 'ComicSparks',
);
const String updateRepo = String.fromEnvironment(
  'UPDATE_REPO',
  defaultValue: 'hibiscus',
);

bool get updateCheckEnabled =>
    updateOwner.trim().isNotEmpty && updateRepo.trim().isNotEmpty;

final updateStatusSignal = signal(const UpdateStatus.unknown());

Future<void> maybeAutoCheckUpdate(BuildContext context) async {
  if (!updateCheckEnabled) {
    AppLogger.debug('update', 'auto check skipped: disabled');
    return;
  }
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final lastMs = int.tryParse(await _loadProperty(_lastUpdateCheckKey)) ?? 0;
  if (nowMs - lastMs < _autoCheckInterval.inMilliseconds) {
    AppLogger.debug('update', 'auto check skipped: interval not reached');
    return;
  }

  final nextPromptMs =
      int.tryParse(await _loadProperty(_nextUpdatePromptMsKey)) ?? 0;
  if (nowMs < nextPromptMs) {
    AppLogger.debug('update', 'auto check skipped: deferred prompt window');
    return;
  }

  late final UpdateStatus status;
  try {
    AppLogger.info('update', 'auto check started');
    status = await _performUpdateCheck();
  } catch (e, stack) {
    AppLogger.warn('update', 'auto check failed: $e', stack: stack);
    return;
  }
  await _saveProperty(_lastUpdateCheckKey, nowMs.toString());
  if (!status.hasUpdate) return;

  final ignoredVersion = (await _loadProperty(_ignoredLatestVersionKey)).trim();
  if (ignoredVersion.isNotEmpty && ignoredVersion == status.latestVersion) {
    AppLogger.debug('update', 'auto check skipped: ignored version');
    return;
  }

  if (!context.mounted) return;
  try {
    await _showUpdateAvailableDialog(context, status, manual: false);
  } catch (e, stack) {
    AppLogger.warn('update', 'show update dialog failed: $e', stack: stack);
  }
}

Future<void> manualCheckUpdate(BuildContext context) async {
  if (!context.mounted) return;
  if (!updateCheckEnabled) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('检查更新'),
          content: const Text('未开启版本更新检查（缺少 UPDATE_OWNER/UPDATE_REPO）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
    return;
  }

  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return const AlertDialog(
        content: SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    },
  );

  late final UpdateStatus status;
  Object? error;
  try {
    status = await _performUpdateCheck();
  } catch (e) {
    error = e;
  }

  if (navigator.mounted) {
    navigator.pop();
  }
  if (!context.mounted) return;

  if (error != null) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('检查更新失败'),
          content: Text(error?.toString() ?? '未知错误'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
    return;
  }

  if (!status.hasUpdate) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('检查更新'),
          content: Text(
            '当前版本：${status.currentVersion}\n'
            '最新版本：${status.latestVersion}\n'
            '暂无可用更新。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
    return;
  }

  await _showUpdateAvailableDialog(context, status, manual: true);
}

Future<UpdateStatus> _performUpdateCheck() async {
  final result = await checkForUpdate();
  final status = UpdateStatus.fromResult(result);
  updateStatusSignal.value = status;
  AppLogger.info(
    'update',
    'check completed: current=${status.currentVersion}, latest=${status.latestVersion}, hasUpdate=${status.hasUpdate}',
  );
  return status;
}

Future<UpdateCheckResult> checkForUpdate({
  Duration timeout = const Duration(seconds: 8),
}) async {
  final currentVersion = await _getCurrentAppVersion();
  final response = await _fetchLatestRelease(timeout: timeout);
  final latestTag = (response['tag_name'] as String?)?.trim() ?? '';
  final latestVersion = _tagToVersion(latestTag);
  final releaseUrl = (response['html_url'] as String?)?.trim();
  final notes = (response['body'] as String?)?.trim();

  final hasUpdate =
      _compareSemver(_tagToVersion(currentVersion), latestVersion) < 0;
  return UpdateCheckResult(
    currentVersion: currentVersion,
    latestVersion: latestVersion.isEmpty ? latestTag : latestVersion,
    releaseUrl: releaseUrl,
    releaseNotes: notes,
    hasUpdate: hasUpdate,
  );
}

Future<Map<String, dynamic>> _fetchLatestRelease({
  required Duration timeout,
}) async {
  final owner = updateOwner.trim();
  final repo = updateRepo.trim();
  if (owner.isEmpty || repo.isEmpty) {
    throw StateError('UPDATE_OWNER/UPDATE_REPO not set');
  }

  final uri = Uri.https(
    'api.github.com',
    '/repos/$owner/$repo/releases/latest',
  );
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'hibiscus');
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub API ${response.statusCode}: $body');
    }
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return json;
  } finally {
    client.close(force: true);
  }
}

Future<String> _getCurrentAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

Future<String> _loadProperty(String key) async {
  return (await RustKvStore.getString(key)) ?? '';
}

Future<void> _saveProperty(String key, String value) async {
  await RustKvStore.setString(key, value);
}

Future<void> _showUpdateAvailableDialog(
  BuildContext context,
  UpdateStatus status, {
  required bool manual,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('发现新版本'),
        content: SingleChildScrollView(
          child: Text(
            '当前版本：${status.currentVersion}\n'
            '最新版本：${status.latestVersion}\n\n'
            '${status.releaseNotes ?? ''}',
          ),
        ),
        actions: [
          if (!manual) ...[
            TextButton(
              onPressed: () async {
                await _saveProperty(
                  _nextUpdatePromptMsKey,
                  (DateTime.now().millisecondsSinceEpoch +
                          _promptOneDay.inMilliseconds)
                      .toString(),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('一天后提醒'),
            ),
            TextButton(
              onPressed: () async {
                await _saveProperty(
                  _nextUpdatePromptMsKey,
                  (DateTime.now().millisecondsSinceEpoch +
                          _promptOneWeek.inMilliseconds)
                      .toString(),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('一周后提醒'),
            ),
            TextButton(
              onPressed: () async {
                await _saveProperty(
                  _ignoredLatestVersionKey,
                  status.latestVersion,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('忽略此版本'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后'),
            ),
          ],
          if (status.releaseUrl != null && status.releaseUrl!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchUrl(status.releaseUrl!);
              },
              child: const Text('打开发布页'),
            ),
        ],
      );
    },
  );
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _tagToVersion(String v) {
  var s = v.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  s = s.split('+').first;
  s = s.split('-').first;
  return s.trim();
}

int _compareSemver(String a, String b) {
  final ap = _parseSemverParts(a);
  final bp = _parseSemverParts(b);
  final maxLen = ap.length > bp.length ? ap.length : bp.length;
  for (var i = 0; i < maxLen; i++) {
    final ai = i < ap.length ? ap[i] : 0;
    final bi = i < bp.length ? bp[i] : 0;
    if (ai != bi) return ai.compareTo(bi);
  }
  return 0;
}

List<int> _parseSemverParts(String v) {
  final s = _tagToVersion(v);
  if (s.isEmpty) return const [0, 0, 0];
  return s
      .split('.')
      .map((part) {
        final match = RegExp(r'^\d+').firstMatch(part.trim());
        return int.tryParse(match?.group(0) ?? '') ?? 0;
      })
      .toList(growable: false);
}

class UpdateCheckResult {
  final String currentVersion;
  final String latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final bool hasUpdate;

  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });
}

class UpdateStatus {
  final String currentVersion;
  final String latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final bool hasUpdate;

  const UpdateStatus({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });

  const UpdateStatus.unknown()
    : currentVersion = '-',
      latestVersion = '-',
      releaseUrl = null,
      releaseNotes = null,
      hasUpdate = false;

  factory UpdateStatus.fromResult(UpdateCheckResult r) {
    return UpdateStatus(
      currentVersion: r.currentVersion,
      latestVersion: r.latestVersion,
      releaseUrl: r.releaseUrl,
      releaseNotes: r.releaseNotes,
      hasUpdate: r.hasUpdate,
    );
  }
}
