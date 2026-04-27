import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeTitle;
  const RecipeDetailScreen({super.key, required this.recipeTitle});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _commentController = TextEditingController();
  int _currentRating = 0;
  
  late stt.SpeechToText _speechToText;
  bool _isListening = false;

  late FlutterTts _flutterTts;
  bool _isPlayingTts = false;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("es-CL");
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlayingTts = false;
      });
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
      // Texto simulado a leer
      String recipeText = "Receta de ${widget.recipeTitle}. Ingredientes: 1 kilo de carne, 2 cebollas. Preparación: Picar todo y cocinar por 40 minutos.";
      await _flutterTts.speak(recipeText);
    }
  }

  // ==== ACCESIBILIDAD: Dictado por Voz para Comentarios ====
  void _listenComment() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) => setState(() {
            _commentController.text = val.recognizedWords;
          }),
          localeId: 'es_CL',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  // ==== COMPARTIR ====
  void _shareRecipe() {
    Share.share(
      '¡Mira esta receta de ${widget.recipeTitle} en Gastronomía a la Chilena! Descarga la app para ver más.',
      subject: widget.recipeTitle,
    );
  }

  // ==== REPORTAR ====
  void _reportContent(String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reportar $type'),
        content: const Text('¿Estás seguro de que deseas reportar este contenido? A los 3 reportes será ocultado para revisión.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              // Lógica de base de datos para insertar reporte
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 28),
            onPressed: _shareRecipe,
            tooltip: 'Compartir Receta',
          ),
          IconButton(
            icon: const Icon(Icons.flag, size: 28),
            onPressed: () => _reportContent('Receta'),
            tooltip: 'Reportar Receta',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
          ),
          const SizedBox(height: 24),
          Text(widget.recipeTitle, style: theme.textTheme.displayMedium),
          const SizedBox(height: 16),
          
          // Botón de lectura de voz (Accesibilidad Mayor)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56), // Touch target grande
              backgroundColor: _isPlayingTts ? Colors.red.shade100 : theme.colorScheme.primaryContainer,
              foregroundColor: _isPlayingTts ? Colors.red : theme.colorScheme.onPrimaryContainer,
            ),
            icon: Icon(_isPlayingTts ? Icons.stop_circle : Icons.play_circle_fill, size: 32),
            label: Text(_isPlayingTts ? 'Detener Lectura' : 'Leer Receta en Voz Alta', style: const TextStyle(fontSize: 20)),
            onPressed: _toggleTts,
          ),
          const SizedBox(height: 24),

          // Estrellas (Calificación)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                iconSize: 48, // Touch target grande
                icon: Icon(
                  index < _currentRating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                ),
                onPressed: () {
                  setState(() => _currentRating = index + 1);
                  // Guardar calificación en Supabase
                },
              );
            }),
          ),
          const Text('Califica esta receta', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          
          const Divider(height: 48, thickness: 2),
          Text('Comentarios', style: theme.textTheme.displaySmall),
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
              IconButton(
                iconSize: 40,
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : theme.colorScheme.primary),
                onPressed: _listenComment,
              ),
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.send, color: theme.colorScheme.primary),
                onPressed: () {
                  // Enviar comentario
                  _commentController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Lista de Comentarios (Ejemplo)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('María Sánchez', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: const Text('¡Me quedó deliciosa, gracias por la receta!', style: TextStyle(fontSize: 16)),
            trailing: IconButton(
              icon: const Icon(Icons.flag, color: Colors.grey),
              onPressed: () => _reportContent('Comentario'),
            ),
          ),
        ],
      ),
    );
  }
}
