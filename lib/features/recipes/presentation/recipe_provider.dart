import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

// Proveedor para el Repositorio
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});

// Proveedor para obtener las recetas del Feed (asíncrono)
final feedRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getFeedRecipes();
});
