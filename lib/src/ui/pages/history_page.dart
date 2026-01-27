// 播放历史页

import 'package:flutter/material.dart';
import 'package:hibiscus/src/router/router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/rust/api/user.dart' as user_api;
import 'package:hibiscus/src/rust/api/models.dart';
import 'package:hibiscus/src/ui/widgets/cached_image.dart' as rust_image;

/// 历史记录状态
class _HistoryState {
  final items = signal<List<ApiPlayHistory>>([]);
  final isLoading = signal(false);
  final hasMore = signal(true);
  final error = signal<String?>(null);
  int _currentPage = 1;
  static const _pageSize = 20;

  Future<void> load({bool refresh = false}) async {
    if (isLoading.value && !refresh) return;

    if (refresh) {
      _currentPage = 1;
      hasMore.value = true;
    }

    isLoading.value = true;
    error.value = null;

    try {
      final result = await user_api.getPlayHistory(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (refresh) {
        items.value = result.items;
      } else {
        items.value = [...items.value, ...result.items];
      }

      hasMore.value = result.hasNext;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    _currentPage++;
    await load();
  }

  Future<void> clearAll() async {
    try {
      await user_api.clearPlayHistory();
      items.value = [];
    } catch (e) {
      // 忽略错误
    }
  }

  void reset() {
    items.value = [];
    isLoading.value = false;
    hasMore.value = true;
    error.value = null;
    _currentPage = 1;
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _state = _HistoryState();
  final _scrollController = ScrollController();
  final _isSelectionMode = signal(false);
  final _selectedIds = signal<Set<String>>(<String>{});
  final _isOperating = signal(false);

  @override
  void initState() {
    super.initState();
    _state.load(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _state.reset();
    super.dispose();
  }

  void _exitSelectionMode() {
    _isSelectionMode.value = false;
    _selectedIds.value = <String>{};
  }

  void _toggleSelected(String videoId) {
    final next = {..._selectedIds.value};
    if (next.contains(videoId)) {
      next.remove(videoId);
    } else {
      next.add(videoId);
    }
    _selectedIds.value = next;
  }

  void _selectAllVisible() {
    _selectedIds.value = {..._state.items.value.map((e) => e.videoId)};
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final ids = _selectedIds.value.toList();
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除历史记录'),
        content: Text('将移除 ${ids.length} 条记录，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _isOperating.value = true;
    try {
      for (final id in ids) {
        await user_api.deletePlayHistory(videoId: id);
      }
      _exitSelectionMode();
      await _state.load(refresh: true);
    } finally {
      _isOperating.value = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _state.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Watch((_) {
          final selecting = _isSelectionMode.value;
          final count = _selectedIds.value.length;
          return Text(selecting ? '已选择 $count' : '播放历史');
        }),
        actions: [
          Watch((context) {
            final selecting = _isSelectionMode.value;
            if (!selecting) {
              return IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: '多选移除',
                onPressed: () => _isSelectionMode.value = true,
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '全选',
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAllVisible,
                ),
                IconButton(
                  tooltip: '移除所选',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _selectedIds.value.isEmpty
                      ? null
                      : () => _deleteSelected(context),
                ),
                IconButton(
                  tooltip: '取消',
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
              ],
            );
          }),
          Watch((context) {
            if (_isSelectionMode.value) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearHistoryDialog(context),
              tooltip: '清除历史',
            );
          }),
        ],
      ),
      body: Watch((context) {
        final items = _state.items.value;
        final isLoading = _state.isLoading.value;
        final error = _state.error.value;
        final hasMore = _state.hasMore.value;
        final isSelectionMode = _isSelectionMode.value;
        final selectedIds = _selectedIds.value;
        final isOperating = _isOperating.value;

        Widget child;
        if (isLoading && items.isEmpty) {
          child = const Center(child: CircularProgressIndicator());
        } else if (error != null && items.isEmpty) {
          child = _buildErrorState(context, error);
        } else if (items.isEmpty) {
          child = _buildEmptyState(context, theme);
        } else {
          child = RefreshIndicator(
            onRefresh: () => _state.load(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final item = items[index];
                final selected = selectedIds.contains(item.videoId);
                return _buildHistoryItem(
                  context,
                  item,
                  isSelectionMode: isSelectionMode,
                  isSelected: selected,
                );
              },
            ),
          );
        }

        if (!isOperating) return child;
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: ColoredBox(
                color: theme.colorScheme.surface.withOpacity(0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    ApiPlayHistory item, {
    required bool isSelectionMode,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final progressPercent = (item.progress * 100).clamp(0, 100);

    const tileHeight = 96.0;
    final lastPlayed = DateTime.fromMillisecondsSinceEpoch(item.lastPlayedAt * 1000);
    final lastPlayedText =
        '${lastPlayed.month.toString().padLeft(2, '0')}-${lastPlayed.day.toString().padLeft(2, '0')} '
        '${lastPlayed.hour.toString().padLeft(2, '0')}:${lastPlayed.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (isSelectionMode) {
              _toggleSelected(item.videoId);
            } else {
              context.pushVideo(item.videoId);
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              _isSelectionMode.value = true;
              _toggleSelected(item.videoId);
            }
          },
          child: SizedBox(
            height: tileHeight,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _HistoryCover(
                        url: item.coverUrl,
                        showSelectedOverlay: isSelectionMode && isSelected,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '观看 ${progressPercent.toStringAsFixed(0)}% · $lastPlayedText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelected(item.videoId),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: (progressPercent / 100).toDouble(),
                    minHeight: 3,
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无播放记录',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('加载失败', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _state.load(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除播放历史'),
        content: const Text('确定要清除所有播放历史吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _state.clearAll();
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCover extends StatelessWidget {
  final String url;
  final bool showSelectedOverlay;

  const _HistoryCover({required this.url, required this.showSelectedOverlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (url.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.video_library_outlined),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: rust_image.CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.video_library_outlined),
            ),
          ),
        ),
        if (showSelectedOverlay)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Center(
                child: Icon(Icons.check_circle, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
