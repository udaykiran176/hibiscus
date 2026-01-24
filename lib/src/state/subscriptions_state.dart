// 订阅状态管理

import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/rust/api/models.dart';
import 'package:hibiscus/src/rust/api/user.dart' as user_api;

class SubscriptionsState {
  static final SubscriptionsState _instance = SubscriptionsState._();
  factory SubscriptionsState() => _instance;
  SubscriptionsState._();

  final authors = signal<List<ApiAuthorInfo>>([]);
  final videos = signal<List<ApiVideoCard>>([]);

  final isLoading = signal(false);
  final hasMore = signal(true);
  final error = signal<String?>(null);

  int _currentPage = 1;

  Future<void> load({bool refresh = false}) async {
    if (isLoading.value && !refresh) return;

    if (refresh) {
      _currentPage = 1;
      hasMore.value = true;
    }

    isLoading.value = true;
    error.value = null;

    try {
      final result = await user_api.getMySubscriptions(page: _currentPage);
      if (refresh) {
        authors.value = result.authors;
        videos.value = result.videos;
      } else {
        if (_currentPage == 1 && result.authors.isNotEmpty) {
          authors.value = result.authors;
        }
        videos.value = [...videos.value, ...result.videos];
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

  void reset() {
    authors.value = [];
    videos.value = [];
    isLoading.value = false;
    hasMore.value = true;
    error.value = null;
    _currentPage = 1;
  }
}

final subscriptionsState = SubscriptionsState();

