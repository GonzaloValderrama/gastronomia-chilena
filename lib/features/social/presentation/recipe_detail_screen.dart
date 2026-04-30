import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../recipes/domain/recipe.dart';
import 'social_provider.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final _commentController = TextEditingController();
  
  late FlutterTts _flutterTts;
  bool _isPlayingTts = false;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("es-CL");
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlayingTts = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // ==== ACCESIBILIDAD: Leer Receta en Voz Alta ====
  Future<void> _toggleTts() async {
    if (_isPlayingTts) {
      await _flutterTts.stop();
      setState(() => _isPlayingTts = false);
    } else {
      setState(() => _isPlayingTts = true);
      
      final recipe = widget.recipe;
      
      StringBuffer ttsText = StringBuffer();
      ttsText.writeln("Receta de ${recipe.title}.");
      if (recipe.description != null) {
        ttsText.writeln("${recipe.description}.");
      }
      
      ttsText.writeln("Ingredientes.");
      for (var ingredient in recipe.ingredients) {
        ttsText.writeln(ingredient);
      }
      
      ttsText.writeln("Preparación.");
      for (int i = 0; i < recipe.instructions.length; i++) {
        ttsText.writeln("Paso ${i + 1}. ${recipe.instructions[i]}");
      }
      
      await _flutterTts.speak(ttsText.toString());
    }
  }

  // ==== COMPARTIR ====
  void _shareRecipe() {
    Share.share(
      '¡Mira esta receta de ${widget.recipe.title} en Gastronomía a la Chilena! Descarga la app para ver más.',
      subject: widget.recipe.title,
    );
  }

  // ==== REPORTAR ====
  void _reportContent(String type, String entityId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reportar $type'),
        content: const Text('¿Estás seguro de que deseas reportar este contenido?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              // TODO: Insertar reporte en la base de datos
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte enviado exitosamente.')),
              );
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  // ==== ENVIAR COMENTARIO ====
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await ref.read(socialRepositoryProvider).addComment(widget.recipe.id, text);
      _commentController.clear();
      // Refrescar los comentarios
      ref.refresh(recipeCommentsProvider(widget.recipe.id));
      if (mounted) {
        FocusScope.of(context).unfocus(); // Cerrar teclado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comentario publicado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  // ==== CALIFICAR ====
  Future<void> _rateRecipe(int score) async {
    try {
      await ref.read(socialRepositoryProvider).upsertRating(widget.recipe.id, score);
      // Refrescar estadísticas
      ref.refresh(recipeStatsProvider(widget.recipe.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por calificar!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = widget.recipe;
    
    final asyncComments = ref.watch(recipeCommentsProvider(recipe.id));
    final asyncStats = ref.watch(recipeStatsProvider(recipe.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 28),
            onPressed: _shareRecipe,
            tooltip: 'Compartir Receta',
          ),
          IconButton(
            icon: const Icon(Icons.flag, size: 28),
            onPressed: () => _reportContent('Receta', recipe.id),
            tooltip: 'Reportar Receta',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Imagen de Portada
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              image: (recipe.mediaUrls != null && recipe.mediaUrls!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(recipe.mediaUrls!.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (recipe.mediaUrls == null || recipe.mediaUrls!.isEmpty)
                ? const Center(child: Icon(Icons.image, size: 64, color: Colors.grey))
                : null,
          ),
          const SizedBox(height: 24),
          
          // Título y Categoría
          Text(recipe.title, style: theme.textTheme.displayMedium),
          const SizedBox(height: 8),
          if (recipe.category != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(recipe.category!, style: const TextStyle(fontSize: 16)),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
            ),
          const SizedBox(height: 16),
          
          // Descripción
          if (recipe.description != null) ...[
            Text(
              recipe.description!,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 24),
          ],
          
          // Tiempo, Porciones y Rating (Stat)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (recipe.prepTimeMinutes != null)
                Row(
                  children: [
                    const Icon(Icons.timer, size: 28, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('${recipe.prepTimeMinutes} min', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (recipe.servings != null)
                Row(
                  children: [
                    const Icon(Icons.people, size: 28, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('${recipe.servings} porc.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              // Promedio de estrellas
              asyncStats.when(
                data: (stats) => Row(
                  children: [
                    const Icon(Icons.star, size: 28, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      stats['count'] > 0 ? (stats['average'] as double).toStringAsFixed(1) : 'N/A',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(' (${stats['count']})', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Botón de lectura de voz
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: _isPlayingTts ? Colors.red.shade100 : theme.colorScheme.primaryContainer,
              foregroundColor: _isPlayingTts ? Colors.red : theme.colorScheme.onPrimaryContainer,
            ),
            icon: Icon(_isPlayingTts ? Icons.stop_circle : Icons.volume_up, size: 36),
            label: Text(_isPlayingTts ? 'Detener Lectura' : 'Escuchar Receta', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            onPressed: _toggleTts,
          ),
          const SizedBox(height: 32),
          
          // Ingredientes
          Text('Ingredientes', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recipe.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                    Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 18))),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),
          
          // Preparación
          Text('Preparación', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(recipe.instructions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      radius: 18,
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        recipe.instructions[index],
                        style: const TextStyle(fontSize: 18, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const Divider(height: 48, thickness: 2),
          
          // Estrellas interactivas (Calificación)
          const Text('Califica esta receta', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          asyncStats.when(
            data: (stats) {
              final userRating = stats['userRating'] as int;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 56, // Touch target gigante
                    icon: Icon(
                      index < userRating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                    onPressed: () => _rateRecipe(index + 1),
                  );
                }),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error cargando calificación')),
          ),
          
          const Divider(height: 48, thickness: 2),
          Text('Comentarios', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Área de nuevo comentario
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un comentario...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSubmittingComment
                  ? const CircularProgressIndicator()
                  : IconButton(
                      iconSize: 40,
                      icon: Icon(Icons.send, color: theme.colorScheme.primary),
                      onPressed: _submitComment,
                    ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Lista de Comentarios Reales
          asyncComments.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aún no hay comentarios. ¡Sé el primero!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: comments.map((comment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: comment.authorAvatarUrl != null ? NetworkImage(comment.authorAvatarUrl!) : null,
                    child: comment.authorAvatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(comment.content, style: const TextStyle(fontSize: 16)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.flag, color: Colors.grey),
                    onPressed: () => _reportContent('Comentario', comment.id),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error cargando comentarios: $err', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
