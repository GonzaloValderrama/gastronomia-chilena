import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/social_repository.dart';
import '../domain/comment.dart';

// Proveedor para el Repositorio Social
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

// Proveedor de Comentarios por Receta
final recipeCommentsProvider = FutureProvider.autoDispose.family<List<Comment>, String>((ref, recipeId) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getComments(recipeId);
});

// Proveedor de Estadísticas y Rating por Receta
final recipeStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, recipeId) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getRecipeStatsWithUser(recipeId);
});
