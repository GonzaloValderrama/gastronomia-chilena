import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/comment.dart';

class SocialRepository {
  final SupabaseClient _supabase;

  SocialRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // ==== COMENTARIOS ====

  /// Obtiene los comentarios de una receta, incluyendo datos del autor
  Future<List<Comment>> getComments(String recipeId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles:author_id(display_name, avatar_url)')
          .eq('recipe_id', recipeId)
          .eq('is_hidden', false)
          .order('created_at', ascending: true);

      final List<dynamic> data = response;
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      print('Error en getComments: $e');
      rethrow;
    }
  }

  /// Añade un comentario a una receta
  Future<void> addComment(String recipeId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Debes iniciar sesión para comentar.');

    try {
      await _supabase.from('comments').insert({
        'recipe_id': recipeId,
        'author_id': userId,
        'content': content,
      });
    } catch (e) {
      print('Error en addComment: $e');
      rethrow;
    }
  }

  // ==== CALIFICACIONES ====

  /// Obtiene el promedio de calificación y el número total de votos
  Future<Map<String, dynamic>> getRecipeStats(String recipeId) async {
    try {
      // Intentamos consultar la vista materializada si está actualizada,
      // pero como la vista materializada se actualiza por cron, 
      // para tiempo real consultaremos la tabla ratings directamente.
      
      final response = await _supabase
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId);
          
      final List<dynamic> data = response;
      if (data.isEmpty) return {'average': 0.0, 'count': 0, 'userRating': 0};
      
      double total = 0;
      for (var row in data) {
        total += (row['score'] as int);
      }
      
      final average = total / data.length;
      
      // Obtener voto del usuario actual si está logueado
      int userRating = 0;
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final userVote = data.where((row) => row['user_id'] == userId).toList();
        // Wait, 'user_id' no lo pedí en el select. Mejor hagamos un select que traiga user_id.
      }
      
      return {'average': average, 'count': data.length};
    } catch (e) {
      print('Error en getRecipeStats: $e');
      return {'average': 0.0, 'count': 0};
    }
  }

  /// Forma correcta de obtener Stats + User Rating
  Future<Map<String, dynamic>> getRecipeStatsWithUser(String recipeId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('score, user_id')
          .eq('recipe_id', recipeId);
          
      final List<dynamic> data = response;
      if (data.isEmpty) return {'average': 0.0, 'count': 0, 'userRating': 0};
      
      double total = 0;
      int userRating = 0;
      final userId = _supabase.auth.currentUser?.id;

      for (var row in data) {
        final score = row['score'] as int;
        total += score;
        if (userId != null && row['user_id'] == userId) {
          userRating = score;
        }
      }
      
      final average = total / data.length;
      return {'average': average, 'count': data.length, 'userRating': userRating};
    } catch (e) {
      print('Error en getRecipeStatsWithUser: $e');
      return {'average': 0.0, 'count': 0, 'userRating': 0};
    }
  }

  /// Inserta o actualiza la calificación del usuario actual
  Future<void> upsertRating(String recipeId, int score) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Debes iniciar sesión para calificar.');

    try {
      await _supabase.from('ratings').upsert(
        {
          'recipe_id': recipeId,
          'user_id': userId,
          'score': score,
        },
        onConflict: 'recipe_id, user_id',
      );
    } catch (e) {
      print('Error en upsertRating: $e');
      rethrow;
    }
  }

  // ==== RANKINGS ====

  /// Obtiene las recetas mejor calificadas
  Future<List<Map<String, dynamic>>> getTopRatedRecipes() async {
    try {
      final response = await _supabase.rpc('get_top_rated_recipes');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getTopRatedRecipes: $e');
      return [];
    }
  }

  /// Obtiene los usuarios con más recetas creadas
  Future<List<Map<String, dynamic>>> getTopContributors() async {
    try {
      final response = await _supabase.rpc('get_top_contributors');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getTopContributors: $e');
      return [];
    }
  }
}
