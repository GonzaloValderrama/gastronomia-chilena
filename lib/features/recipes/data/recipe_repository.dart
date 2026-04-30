import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/recipe.dart';

class RecipeRepository {
  final SupabaseClient _supabase;

  RecipeRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Obtiene las recetas públicas para el Feed, ordenadas por fecha de creación descendente.
  Future<List<Recipe>> getFeedRecipes() async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(20);

      final List<dynamic> data = response;
      return data.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Error en getFeedRecipes: $e');
      rethrow;
    }
  }

  /// Crea una nueva receta
  Future<Recipe> createRecipe({
    required String title,
    String? description,
    required List<String> ingredients,
    required List<String> instructions,
    int? prepTimeMinutes,
    int? servings,
    String? category,
    List<String>? mediaUrls,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('El usuario debe estar autenticado para crear una receta.');
      }

      final response = await _supabase.from('recipes').insert({
        'author_id': userId,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'prep_time_minutes': prepTimeMinutes,
        'servings': servings,
        'category': category,
        'media_urls': mediaUrls,
        // is_hidden es false por defecto
      }).select().single();

      return Recipe.fromJson(response);
    } catch (e) {
      print('Error en createRecipe: $e');
      rethrow;
    }
  }

  /// Obtiene recetas por categoría
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('is_hidden', false)
          .eq('category', category)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Error en getRecipesByCategory: $e');
      rethrow;
    }
  }

  /// Obtiene recetas por letra inicial (ignorando mayúsculas/minúsculas)
  Future<List<Recipe>> getRecipesByLetter(String letter) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('is_hidden', false)
          .ilike('title', '$letter%') // Usar ilike para ignorar case sensitiveness
          .order('title', ascending: true); // Orden alfabético

      final List<dynamic> data = response;
      return data.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Error en getRecipesByLetter: $e');
      rethrow;
    }
  }

  /// Obtiene las recetas creadas por el usuario autenticado actual
  Future<List<Recipe>> getUserRecipes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return []; // Si no hay usuario, retornar lista vacía
      }

      final response = await _supabase
          .from('recipes')
          .select()
          .eq('author_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Error en getUserRecipes: $e');
      rethrow;
    }
  }

  /// Actualiza una receta existente (sujeta al límite de ediciones en Supabase)
  Future<Recipe> updateRecipe(
      String recipeId, {
        String? title,
        String? description,
        List<String>? ingredients,
        List<String>? instructions,
        int? prepTimeMinutes,
        int? servings,
        String? category,
        List<String>? mediaUrls,
      }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (ingredients != null) updates['ingredients'] = ingredients;
      if (instructions != null) updates['instructions'] = instructions;
      if (prepTimeMinutes != null) updates['prep_time_minutes'] = prepTimeMinutes;
      if (servings != null) updates['servings'] = servings;
      if (category != null) updates['category'] = category;
      if (mediaUrls != null) updates['media_urls'] = mediaUrls;

      final response = await _supabase
          .from('recipes')
          .update(updates)
          .eq('id', recipeId)
          .eq('author_id', userId)
          .select()
          .single();

      return Recipe.fromJson(response);
    } catch (e) {
      print('Error en updateRecipe: $e');
      if (e is PostgrestException && e.message.contains('3 ediciones')) {
        throw Exception('Has alcanzado el límite máximo de 3 ediciones para esta receta.');
      }
      rethrow;
    }
  }

  /// Añadir o remover receta de favoritos
  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado.');

      if (isFavorite) {
        await _supabase.from('favorite_recipes').insert({
          'user_id': userId,
          'recipe_id': recipeId,
        });
      } else {
        await _supabase.from('favorite_recipes')
            .delete()
            .eq('user_id', userId)
            .eq('recipe_id', recipeId);
      }
    } catch (e) {
      print('Error en toggleFavorite: $e');
      rethrow;
    }
  }

  /// Verifica si una receta es favorita
  Future<bool> isFavorite(String recipeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('favorite_recipes')
          .select('id')
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error en isFavorite: $e');
      return false;
    }
  }

  /// Obtiene todas las recetas favoritas del usuario actual
  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('favorite_recipes')
          .select('recipes(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      // Extract the nested 'recipes' objects
      return data.map((item) => Recipe.fromJson(item['recipes'])).toList();
    } catch (e) {
      print('Error en getFavoriteRecipes: $e');
      rethrow;
    }
  }
}
