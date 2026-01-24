import 'package:flutter/material.dart';
import 'package:hibiscus/src/router/router.dart';
import 'package:hibiscus/src/rust/api/models.dart';
import 'package:hibiscus/src/ui/theme/app_theme.dart';

class VideoPagerPage {
  final List<ApiVideoCard> videos;
  final bool hasNext;

  const VideoPagerPage({
    required this.videos,
    required this.hasNext,
  });
}

class VideoPager extends StatefulWidget {
  final Future<VideoPagerPage> Function(int page) pageLoader;
  final ValueChanged<List<ApiVideoCard>>? onItemsChanged;

  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<ApiVideoCard>? onToggleSelect;

  final Widget Function(
    BuildContext context,
    ApiVideoCard video,
    double sizeScale,
    bool selected,
    VoidCallback onTap,
  ) itemBuilder;

  const VideoPager({
    super.key,
    required this.pageLoader,
    required this.itemBuilder,
    this.onItemsChanged,
    this.selectionMode = false,
    this.selectedIds = const <String>{},
    this.onToggleSelect,
  });

  @override
  State<VideoPager> createState() => _VideoPagerState();
}

class _VideoPagerState extends State<VideoPager> {
  final ScrollController _scrollController = ScrollController();

  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<ApiVideoCard> _videos = const <ApiVideoCard>[];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyItems() {
    widget.onItemsChanged?.call(_videos);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _page = 1;
      _hasMore = true;
      _isLoading = true;
      _error = null;
      _videos = const <ApiVideoCard>[];
    });
    _notifyItems();

    try {
      final result = await widget.pageLoader(1);
      if (!mounted) return;
      setState(() {
        _videos = result.videos;
        _hasMore = result.hasNext;
        _error = null;
      });
      _notifyItems();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _page++;
    });

    try {
      final result = await widget.pageLoader(_page);
      if (!mounted) return;
      setState(() {
        _videos = [..._videos, ...result.videos];
        _hasMore = result.hasNext;
      });
      _notifyItems();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _page = (_page - 1).clamp(1, 1 << 30);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return _buildErrorState(context, _error!);
      }
      return _buildEmptyState(context);
    }

    final showViews = _videos.any((v) => v.views != null);
    final columns = Breakpoints.getGridColumns(context);
    const padding = EdgeInsets.all(12);
    const spacing = 12.0;

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = _calculateItemWidth(
            columns: columns,
            maxWidth: constraints.maxWidth,
            padding: padding,
            spacing: spacing,
          );
          final sizeScale = _calculateSizeScale(itemWidth);
          final childAspectRatio = _calculateChildAspectRatio(
            context: context,
            columns: columns,
            maxWidth: constraints.maxWidth,
            padding: padding,
            spacing: spacing,
            showViews: showViews,
            sizeScale: sizeScale,
          );

          return GridView.builder(
            controller: _scrollController,
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _videos.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _videos.length) {
                return _buildLoadingIndicator();
              }

              final video = _videos[index];
              final selected = widget.selectedIds.contains(video.id);
              void handleTap() {
                if (widget.selectionMode) {
                  widget.onToggleSelect?.call(video);
                } else {
                  context.pushVideo(video.id);
                }
              }

              return widget.itemBuilder(
                context,
                video,
                sizeScale,
                selected,
                handleTap,
              );
            },
          );
        },
      ),
    );
  }

  double _calculateItemWidth({
    required int columns,
    required double maxWidth,
    required EdgeInsets padding,
    required double spacing,
  }) {
    if (columns <= 0 || maxWidth <= 0) return 0;
    final available = maxWidth - padding.horizontal - spacing * (columns - 1);
    return available > 0 ? available / columns : 0;
  }

  double _calculateSizeScale(double itemWidth) {
    if (itemWidth <= 0) return 1.0;
    final raw = itemWidth / 180.0;
    return raw.clamp(0.9, 1.2);
  }

  double _calculateChildAspectRatio({
    required BuildContext context,
    required int columns,
    required double maxWidth,
    required EdgeInsets padding,
    required double spacing,
    required bool showViews,
    required double sizeScale,
  }) {
    if (columns <= 0 || maxWidth <= 0) return 1.0;

    final itemWidth = _calculateItemWidth(
      columns: columns,
      maxWidth: maxWidth,
      padding: padding,
      spacing: spacing,
    );
    if (itemWidth <= 0) return 1.0;

    final coverHeight = itemWidth * 9 / 16;
    final infoHeight = _estimateInfoHeight(
      context,
      showViews: showViews,
      sizeScale: sizeScale,
    );
    final itemHeight = coverHeight + infoHeight + 5.0 * sizeScale;

    return itemWidth / itemHeight;
  }

  double _estimateInfoHeight(
    BuildContext context, {
    required bool showViews,
    required double sizeScale,
  }) {
    final paddingVertical = 8.0 * 2 * sizeScale;
    final betweenText = 4.0 * sizeScale;

    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    double lineHeight(TextStyle? style, double fallback) {
      final fontSize = (style?.fontSize ?? fallback) * sizeScale;
      final heightFactor = style?.height ?? 1.2;
      final scaledFontSize = scaler.scale(fontSize);
      return scaledFontSize * heightFactor;
    }

    final titleLine = lineHeight(theme.textTheme.bodyMedium, 14);
    final viewsLine = showViews ? lineHeight(theme.textTheme.bodySmall, 12) : 0.0;

    return paddingVertical +
        titleLine +
        (showViews ? (betweenText + viewsLine) : 0.0);
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无视频',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试其他搜索条件',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
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
            Text(
              '加载失败',
              style: theme.textTheme.titleLarge,
            ),
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
              onPressed: _loadFirstPage,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
