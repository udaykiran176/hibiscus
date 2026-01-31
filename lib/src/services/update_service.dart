import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hibiscus/src/services/app_logger.dart';
import 'package:hibiscus/src/services/remote_config_service.dart';
import 'package:hibiscus/src/services/rust_kv_store.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _lastUpdateCheckKey = 'update.last_check_ms';
const _nextUpdatePromptMsKey = 'update.next_prompt_ms';
const _ignoredLatestVersionKey = 'update.ignored_version';

const Duration _autoCheckInterval = Duration(seconds: 10);
const Duration _promptOneDay = Duration(days: 1);
const Duration _promptOneWeek = Duration(days: 7);

const String updateOwner = String.fromEnvironment(
  'UPDATE_OWNER',
  defaultValue: '',
);
const String updateRepo = String.fromEnvironment(
  'UPDATE_REPO',
  defaultValue: '',
);

final updateRepoSpecSignal = signal<UpdateRepoSpec?>(null);

final updateStatusSignal = signal(const UpdateStatus.unknown());

class UpdateRepoSpec {
  final String owner;
  final String repo;

  const UpdateRepoSpec({required this.owner, required this.repo});
}

Future<void> preloadUpdateRepo() async {
  await _resolveUpdateRepo(allowNetwork: false);
}

Future<void> maybeAutoCheckUpdate(BuildContext context) async {
  final repoSpec = await _resolveUpdateRepo(allowNetwork: true);
  if (repoSpec == null) {
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
  final canPrompt = nowMs >= nextPromptMs;

  late final UpdateStatus status;
  try {
    AppLogger.info('update', 'auto check started');
    status = await _performUpdateCheck(repoSpec: repoSpec);
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

  if (!canPrompt) {
    AppLogger.debug('update', 'auto check: update found but prompt deferred');
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
  final rootContext = context;
  if (!rootContext.mounted) return;

  final repoSpec = await _resolveUpdateRepo(allowNetwork: true);
  if (!rootContext.mounted) return;
  if (repoSpec == null) {
    await showDialog<void>(
      context: rootContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('检查更新'),
          content: const Text('未开启版本更新检查（缺少远程配置 repo 或 UPDATE_OWNER/UPDATE_REPO）'),
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

  final navigator = Navigator.of(rootContext);
  showDialog<void>(
    context: rootContext,
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
    status = await _performUpdateCheck(repoSpec: repoSpec);
  } catch (e) {
    error = e;
  }

  if (navigator.mounted) {
    navigator.pop();
  }
  if (!rootContext.mounted) return;

  if (error != null) {
    await showDialog<void>(
      context: rootContext,
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
    final notesMd = (status.releaseNotes ?? '').trim();
    await showDialog<void>(
      context: rootContext,
      builder: (context) {
        final maxContentHeight = MediaQuery.sizeOf(context).height * 0.6;
        return AlertDialog(
          title: const Text('检查更新'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxContentHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前版本：${status.currentVersion}\n'
                    '最新版本：${status.latestVersion}\n'
                    '暂无可用更新。',
                  ),
                  if (notesMd.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: notesMd,
                      onTapLink: (text, href, title) {
                        if (href == null) return;
                        _launchUrl(href);
                      },
                    ),
                  ],
                ],
              ),
            ),
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

  await _showUpdateAvailableDialog(rootContext, status, manual: true);
}

Future<UpdateStatus> _performUpdateCheck({
  required UpdateRepoSpec repoSpec,
}) async {
  final result = await checkForUpdate(repoSpec: repoSpec);
  final status = UpdateStatus.fromResult(result);
  updateStatusSignal.value = status;
  AppLogger.info(
    'update',
    'check completed: current=${status.currentVersion}, latest=${status.latestVersion}, hasUpdate=${status.hasUpdate}',
  );
  return status;
}

Future<UpdateCheckResult> checkForUpdate({
  required UpdateRepoSpec repoSpec,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final currentVersion = await _getCurrentAppVersion();
  final response = await _fetchLatestRelease(repoSpec: repoSpec, timeout: timeout);
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
  required UpdateRepoSpec repoSpec,
  required Duration timeout,
}) async {
  final uri = Uri.https(
    'api.github.com',
    '/repos/${repoSpec.owner}/${repoSpec.repo}/releases/latest',
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

Future<UpdateRepoSpec?> _resolveUpdateRepo({required bool allowNetwork}) async {
  final existing = updateRepoSpecSignal.value;
  if (existing != null) return existing;

  final fromEnv = _parseRepoSpec('${updateOwner.trim()}/${updateRepo.trim()}');
  if (fromEnv != null) {
    await _syncConfigRepoHints(fromEnv);
    updateRepoSpecSignal.value = fromEnv;
    return fromEnv;
  }

  final hinted = await _loadUpdateRepoHints();
  if (hinted != null) {
    updateRepoSpecSignal.value = hinted;
    return hinted;
  }

  final cached = await loadCachedRemoteConfig();
  final cachedSpec = _parseRepoSpec(cached?.repo);
  if (cachedSpec != null) {
    await _syncConfigRepoHints(cachedSpec);
    updateRepoSpecSignal.value = cachedSpec;
    return cachedSpec;
  }

  if (!allowNetwork) {
    return null;
  }

  final cfg = await getRemoteConfig(forceRefresh: true);
  final fetchedSpec = _parseRepoSpec(cfg?.repo);
  if (fetchedSpec != null) {
    await _syncConfigRepoHints(fetchedSpec);
  }
  updateRepoSpecSignal.value = fetchedSpec;
  return fetchedSpec;
}

Future<void> _syncConfigRepoHints(UpdateRepoSpec spec) async {
  await RustKvStore.setString('remote_config.owner', spec.owner);
  await RustKvStore.setString('remote_config.repo_name', spec.repo);
}

Future<UpdateRepoSpec?> _loadUpdateRepoHints() async {
  final owner = (await RustKvStore.getString('remote_config.owner'))?.trim() ?? '';
  final repo = (await RustKvStore.getString('remote_config.repo_name'))?.trim() ?? '';
  if (owner.isEmpty || repo.isEmpty) return null;
  return UpdateRepoSpec(owner: owner, repo: repo);
}

UpdateRepoSpec? _parseRepoSpec(String? input) {
  final raw = (input ?? '').trim();
  if (raw.isEmpty) return null;

  // Accept both "owner/repo" and "https://github.com/owner/repo".
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    if (segments.length < 2) return null;
    return UpdateRepoSpec(owner: segments[0], repo: segments[1]);
  }

  final parts = raw.split('/');
  if (parts.length != 2) return null;
  final owner = parts[0].trim();
  final repo = parts[1].trim();
  if (owner.isEmpty || repo.isEmpty) return null;
  return UpdateRepoSpec(owner: owner, repo: repo);
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
  final notesMd = (status.releaseNotes ?? '').trim();
  await showDialog<void>(
    context: context,
    builder: (context) {
      final maxContentHeight = MediaQuery.sizeOf(context).height * 0.6;
      final maxContentWidth = MediaQuery.sizeOf(context).width * 0.8;
      return AlertDialog(
        title: const Text('发现新版本'),
        content: SizedBox(
          width: maxContentWidth.clamp(280.0, 500.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxContentHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前版本：${status.currentVersion}\n'
                    '最新版本：${status.latestVersion}',
                  ),
                  if (notesMd.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: notesMd,
                      onTapLink: (text, href, title) {
                        if (href == null) return;
                        _launchUrl(href);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (!manual) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后'),
            ),
            PopupMenuButton<_UpdatePromptAction>(
              tooltip: '更多',
              icon: const Icon(Icons.more_vert),
              onSelected: (action) async {
                switch (action) {
                  case _UpdatePromptAction.remindOneDay:
                    await _saveProperty(
                      _nextUpdatePromptMsKey,
                      (DateTime.now().millisecondsSinceEpoch +
                              _promptOneDay.inMilliseconds)
                          .toString(),
                    );
                    break;
                  case _UpdatePromptAction.remindOneWeek:
                    await _saveProperty(
                      _nextUpdatePromptMsKey,
                      (DateTime.now().millisecondsSinceEpoch +
                              _promptOneWeek.inMilliseconds)
                          .toString(),
                    );
                    break;
                  case _UpdatePromptAction.ignoreThisVersion:
                    await _saveProperty(
                      _ignoredLatestVersionKey,
                      status.latestVersion,
                    );
                    break;
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _UpdatePromptAction.remindOneDay,
                  child: Text('一天后提醒'),
                ),
                PopupMenuItem(
                  value: _UpdatePromptAction.remindOneWeek,
                  child: Text('一周后提醒'),
                ),
                PopupMenuItem(
                  value: _UpdatePromptAction.ignoreThisVersion,
                  child: Text('忽略此版本'),
                ),
              ],
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

enum _UpdatePromptAction {
  remindOneDay,
  remindOneWeek,
  ignoreThisVersion,
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
