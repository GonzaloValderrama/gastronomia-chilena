import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'video_trimmer_screen.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Comida caliente', 'Comida fría', 'Repostería'];

  final List<File> _photos = [];
  final List<File> _videos = []; // Máx 2

  final ImagePicker _picker = ImagePicker();
  
  // Instancia de Speech To Text
  late stt.SpeechToText _speechToText;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ==== ACCESIBILIDAD: Dictado por Voz ====
  void _listen(TextEditingController controller) async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) => setState(() {
            controller.text = val.recognizedWords;
          }),
          localeId: 'es_CL', // Español de Chile
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  // ==== MULTIMEDIA: Seleccionar Fotos ====
  Future<void> _pickImages() async {
    if (_photos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límite de 10 fotos alcanzado.')),
      );
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.map((img) => File(img.path)).take(10 - _photos.length));
      });
    }
  }

  // ==== MULTIMEDIA: Seleccionar Video y Recortar ====
  Future<void> _pickVideo() async {
    if (_videos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límite de 2 videos alcanzado.')),
      );
      return;
    }
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      // Redirigir a la pantalla de recorte de video
      final File? trimmedVideo = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoTrimmerScreen(file: File(video.path)),
        ),
      );

      if (trimmedVideo != null) {
        setState(() {
          _videos.add(trimmedVideo);
        });
      }
    }
  }

  // ==== SUBIDA A SUPABASE ====
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Aquí validamos límite diario de forma optimista (aunque el DB trigger lo bloquea)
    // Subida simulada para el paso actual
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Subiendo receta y multimedia...'),
          ],
        ),
      ),
    );

    try {
      // Simular retraso de subida
      await Future.delayed(const Duration(seconds: 2));

      // Ejemplo de cómo se subiría un archivo a Supabase Storage:
      // final bytes = await _photos.first.readAsBytes();
      // await Supabase.instance.client.storage.from('recipe_media').uploadBinary('ruta_archivo', bytes);

      // Ejemplo de Inserción:
      // await Supabase.instance.client.from('recipes').insert({...});

      Navigator.pop(context); // Cerrar diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Receta publicada con éxito!', style: TextStyle(fontSize: 18))),
      );
      Navigator.pop(context); // Volver al feed
    } catch (e) {
      Navigator.pop(context);
      // El mensaje capturará la excepción del Trigger (Límite diario o palabra prohibida)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}', style: const TextStyle(fontSize: 18))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Receta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Título de la receta',
              theme: theme,
              enableSTT: true,
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ingredientsController,
              label: 'Ingredientes (Separados por coma)',
              theme: theme,
              enableSTT: true,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _instructionsController,
              label: 'Instrucciones paso a paso',
              theme: theme,
              enableSTT: true,
              maxLines: 6,
            ),
            const Divider(height: 48, thickness: 2),
            Text('Multimedia', style: theme.textTheme.displaySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate, size: 28),
                    label: Text('Fotos (${_photos.length}/10)'),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_call, size: 28),
                    label: Text('Videos (${_videos.length}/2)'),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('PUBLICAR RECETA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    bool enableSTT = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        suffixIcon: enableSTT
            ? IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.red : theme.colorScheme.primary,
                  size: 32,
                ),
                onPressed: () => _listen(controller),
                tooltip: 'Dictar por Voz',
              )
            : null,
      ),
    );
  }
}
