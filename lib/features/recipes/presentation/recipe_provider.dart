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

// Proveedor para obtener recetas por categoría
final recipesByCategoryProvider = FutureProvider.autoDispose.family<List<Recipe>, String>((ref, category) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesByCategory(category);
});

// Proveedor para obtener recetas por letra inicial
final recipesByLetterProvider = FutureProvider.autoDispose.family<List<Recipe>, String>((ref, letter) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesByLetter(letter);
});
