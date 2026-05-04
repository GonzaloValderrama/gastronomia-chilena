import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

final topRatedRecipesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getTopRatedRecipes();
});

final topContributorsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getTopContributors();
});
