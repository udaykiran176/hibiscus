import 'package:hibiscus/src/services/remote_config_service.dart';
import 'package:signals/signals_flutter.dart';

final recommendationsSignal = signal<List<RecommendationItem>>(
  const <RecommendationItem>[],
);
final recommendationsLoadingSignal = signal<bool>(false);

class RecommendationItem {
  final String title;
  final String? subtitle;
  final String url;

  const RecommendationItem({
    required this.title,
    required this.subtitle,
    required this.url,
  });
}

Future<void> refreshRecommendations({
  bool forceRefresh = false,
  Duration timeout = const Duration(seconds: 8),
}) async {
  recommendationsLoadingSignal.value = true;
  try {
    final cfg = await getRemoteConfig(forceRefresh: forceRefresh, timeout: timeout);
    final links = cfg?.links ?? const <String, String>{};
    if (links.isEmpty) {
      recommendationsSignal.value = const <RecommendationItem>[];
      return;
    }
    final keys = links.keys.toList()..sort();
    recommendationsSignal.value = keys
        .map(
          (k) => RecommendationItem(title: k, subtitle: null, url: links[k] ?? ''),
        )
        .where((e) => e.url.trim().isNotEmpty)
        .toList(growable: false);
  } finally {
    recommendationsLoadingSignal.value = false;
  }
}
