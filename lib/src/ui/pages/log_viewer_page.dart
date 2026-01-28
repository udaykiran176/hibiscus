import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<FileSystemEntity> _files = const [];
  File? _selectedFile;
  String _content = '';
  bool _loading = true;
  bool _following = true;
  Timer? _followTimer;

  static const _maxLines = 2000;

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Directory> _logDir() async {
    final dir = await getApplicationSupportDirectory();
    return Directory(_joinPath(dir.path, 'logs'));
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final dir = await _logDir();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
        final files = dir
          .listSync()
          .where((e) => e is File && e.path.endsWith('.log'))
          .toList();
      files.sort((a, b) {
        final am = a.statSync().modified;
        final bm = b.statSync().modified;
        return bm.compareTo(am);
      });

      _files = files;
      _selectedFile = (_selectedFile != null &&
              files.any((f) => f.path == _selectedFile!.path))
          ? _selectedFile
          : (files.isNotEmpty ? File(files.first.path) : null);
      if (_selectedFile != null) {
        await _reloadSelected();
      } else {
        _content = '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadSelected() async {
    final file = _selectedFile;
    if (file == null) return;
    final text = await _readTailText(file, maxLines: _maxLines);
    if (!mounted) return;
    setState(() => _content = text);
    _applyFilter();
    _scrollToBottomSoon();
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) setState(() {});
      return;
    }
    if (mounted) setState(() {});
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_following) return;
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _setFollowing(bool v) {
    setState(() => _following = v);
    _followTimer?.cancel();
    _followTimer = null;

    if (!_following) return;
    _followTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _reloadSelected();
    });
  }

  List<String> _visibleLines() {
    final query = _searchController.text.trim();
    final lines = const LineSplitter().convert(_content);
    if (query.isEmpty) return lines;
    return lines.where((l) => l.contains(query)).toList();
  }

  Future<String> _readTailText(File file, {required int maxLines}) async {
    final raf = await file.open();
    try {
      final len = await raf.length();
      if (len == 0) return '';

      const chunkSize = 64 * 1024;
      var offset = len;
      var newlines = 0;
      final chunks = <Uint8List>[];

      while (offset > 0 && newlines <= maxLines + 50) {
        final start = (offset - chunkSize) >= 0 ? (offset - chunkSize) : 0;
        final size = (offset - start).toInt();
        await raf.setPosition(start);
        final bytes = await raf.read(size);
        chunks.add(Uint8List.fromList(bytes));
        for (final b in bytes) {
          if (b == 0x0A) newlines++;
        }
        offset = start;
      }

      final combined = BytesBuilder(copy: false);
      for (var i = chunks.length - 1; i >= 0; i--) {
        combined.add(chunks[i]);
      }
      final text = utf8.decode(combined.takeBytes(), allowMalformed: true);
      final lines = const LineSplitter().convert(text);
      final tail = lines.length > maxLines ? lines.sublist(lines.length - maxLines) : lines;
      return tail.join('\n');
    } finally {
      await raf.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _visibleLines();
    final selected = _selectedFile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志预览'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _loadFiles,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: _following ? '停止跟随' : '跟随',
            onPressed: () => _setFollowing(!_following),
            icon: Icon(_following ? Icons.pause_circle : Icons.play_circle),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;

                final filePicker = DropdownButtonFormField<String>(
                  initialValue: selected?.path,
                  decoration: const InputDecoration(
                    labelText: '日志文件',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _files.map((e) {
                    final path = e.path;
                    return DropdownMenuItem(
                      value: path,
                      child: Text(_basename(path)),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _selectedFile = File(value));
                    await _reloadSelected();
                  },
                );

                final searchBox = TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: '搜索',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: isNarrow
                          ? Column(
                              children: [
                                filePicker,
                                const SizedBox(height: 8),
                                searchBox,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: filePicker),
                                const SizedBox(width: 12),
                                SizedBox(width: 220, child: searchBox),
                              ],
                            ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: _selectedFile == null
                            ? const Center(child: Text('没有找到日志文件'))
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount: lines.length,
                                itemBuilder: (context, index) {
                                  return SelectableText(
                                    lines[index],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

String _joinPath(String a, String b) {
  final sep = Platform.pathSeparator;
  if (a.endsWith(sep)) return '$a$b';
  return '$a$sep$b';
}

String _basename(String path) {
  final sep = Platform.pathSeparator;
  final normalized = path.replaceAll('\\', sep).replaceAll('/', sep);
  final parts = normalized.split(sep);
  return parts.isNotEmpty ? parts.last : path;
}
