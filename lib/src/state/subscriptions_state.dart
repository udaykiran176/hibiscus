// 订阅状态管理

import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/rust/api/models.dart';

class SubscriptionsState {
  static final SubscriptionsState _instance = SubscriptionsState._();
  factory SubscriptionsState() => _instance;
  SubscriptionsState._();

  final authors = signal<List<ApiAuthorInfo>>([]);
  final videos = signal<List<ApiVideoCard>>([]);

  void reset() {
    authors.value = [];
    videos.value = [];
  }
}

final subscriptionsState = SubscriptionsState();
