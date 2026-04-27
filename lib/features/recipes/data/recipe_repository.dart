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
}
