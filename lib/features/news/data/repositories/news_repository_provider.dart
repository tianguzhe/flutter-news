import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/news_api_provider.dart';
import 'news_repository.dart';

part 'news_repository_provider.g.dart';

@Riverpod(keepAlive: true)
/// Provides the news repository used by presentation view models.
NewsRepository newsRepository(Ref ref) {
  return NewsRepositoryImpl(ref.watch(newsApiProvider));
}
