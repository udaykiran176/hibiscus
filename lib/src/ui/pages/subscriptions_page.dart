// 订阅页

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/state/subscriptions_state.dart';
import 'package:hibiscus/src/state/user_state.dart';
import 'package:hibiscus/src/ui/pages/login_page.dart';
import 'package:hibiscus/src/ui/widgets/video_grid.dart';
import 'package:hibiscus/src/rust/api/models.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (userState.loginStatus.value == LoginStatus.unknown) {
      userState.checkLoginStatus().then((_) {
        if (mounted && userState.isLoggedIn) {
          subscriptionsState.load(refresh: true);
        }
      });
    } else if (userState.isLoggedIn) {
      subscriptionsState.load(refresh: true);
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    subscriptionsState.reset();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      subscriptionsState.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的订阅')),
      body: Watch((context) {
        final loginStatus = userState.loginStatus.value;
        if (loginStatus != LoginStatus.loggedIn) {
          return _buildNeedLogin(context, theme, loginStatus);
        }

        final authors = subscriptionsState.authors.value;
        final videos = subscriptionsState.videos.value;
        final isLoading = subscriptionsState.isLoading.value;
        final error = subscriptionsState.error.value;
        final hasMore = subscriptionsState.hasMore.value;

        if (isLoading && videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (error != null && videos.isEmpty) {
          return _buildErrorState(context, error);
        }

        return RefreshIndicator(
          onRefresh: () => subscriptionsState.load(refresh: true),
          child: Column(
            children: [
              if (authors.isNotEmpty) _buildAuthorsStrip(context, authors),
              Expanded(
                child: VideoGrid(
                  controller: _scrollController,
                  videos: videos,
                  isLoading: isLoading,
                  hasMore: hasMore,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAuthorsStrip(BuildContext context, List<ApiAuthorInfo> authors) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: authors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final a = authors[index];
          final name = a.name;
          final avatarUrl = a.avatarUrl;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 64,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNeedLogin(BuildContext context, ThemeData theme, LoginStatus status) {
    final subtitle = switch (status) {
      LoginStatus.unknown => '正在检查登录状态…',
      LoginStatus.loggedOut => '登录后才能查看订阅更新',
      LoginStatus.loggedIn => '',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
            const SizedBox(height: 16),
            Text('需要登录', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: status == LoginStatus.unknown
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                      await userState.checkLoginStatus();
                      if (mounted && userState.isLoggedIn) {
                        await subscriptionsState.load(refresh: true);
                      }
                    },
              icon: const Icon(Icons.login),
              label: const Text('去登录'),
            ),
          ],
        ),
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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('加载失败', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => subscriptionsState.load(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
