import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

// Proveedor para el Repositorio
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});

// Estado de filtros del Feed
final feedCategoryProvider = StateProvider<String>((ref) => 'Todas');
final feedSearchQueryProvider = StateProvider<String>((ref) => '');

// Proveedor para obtener las recetas del Feed con filtros aplicados
final filteredFeedRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final category = ref.watch(feedCategoryProvider);
  final query = ref.watch(feedSearchQueryProvider);

  return repository.searchFeedRecipes(category: category, query: query);
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

// Proveedor para obtener las recetas subidas por el usuario autenticado
final userRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getUserRecipes();
});

// Proveedor para obtener las recetas favoritas del usuario autenticado
final favoriteRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getFavoriteRecipes();
});

// Proveedor para verificar si una receta es favorita (por ID)
final isFavoriteRecipeProvider = Provider.autoDispose.family<AsyncValue<bool>, String>((ref, recipeId) {
  final favoritesAsync = ref.watch(favoriteRecipesProvider);
  
  return favoritesAsync.whenData((favorites) {
    return favorites.any((recipe) => recipe.id == recipeId);
  });
});
