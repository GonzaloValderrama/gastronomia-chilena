import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'recipe_provider.dart';

class CreateRecipeScreen extends ConsumerStatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _servingsController = TextEditingController();

  final List<Map<String, TextEditingController>> _ingredientRows = [];
  final List<Map<String, dynamic>> _instructionSteps = [];
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Comida caliente', 'Comida fría', 'Repostería'];
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Añadir 3 filas iniciales
    for (int i = 0; i < 3; i++) {
      _addIngredientRow();
    }
    // Añadir 1 paso inicial
    _addInstructionStep();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening(TextEditingController controller) async {
    if (_speechEnabled) {
      // Detener si ya está escuchando
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      // Almacenar el texto inicial antes de empezar a escuchar
      final initialText = controller.text;
      
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            // Reemplazar o concatenar inteligentemente
            controller.text = initialText.isNotEmpty 
                ? '$initialText ${result.recognizedWords}'
                : result.recognizedWords;
          });
        },
        localeId: 'es_CL', // Preferir español de Chile si está disponible
      );
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El dictado por voz no está disponible o no se dieron permisos.')),
        );
      }
    }
  }

  void _addIngredientRow() {
    if (_ingredientRows.length < 20) {
      setState(() {
        _ingredientRows.add({
          'cantidad': TextEditingController(),
          'ingrediente': TextEditingController(),
        });
      });
    }
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredientRows[index]['cantidad']?.dispose();
      _ingredientRows[index]['ingrediente']?.dispose();
      _ingredientRows.removeAt(index);
    });
  }

  void _addInstructionStep() {
    if (_instructionSteps.length < 20) {
      setState(() {
        _instructionSteps.add({
          'text': TextEditingController(),
          'image': null,
        });
      });
    }
  }

  void _removeInstructionStep(int index) {
    setState(() {
      (_instructionSteps[index]['text'] as TextEditingController).dispose();
      _instructionSteps.removeAt(index);
    });
  }

  Future<void> _pickImageForInstruction(int index) async {
    try {
      final XFile? image = await _picker.pickImage(imageQuality: 80, source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _instructionSteps[index]['image'] = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _removeImageForInstruction(int index) {
    setState(() {
      _instructionSteps[index]['image'] = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();
    for (var row in _ingredientRows) {
      row['cantidad']?.dispose();
      row['ingrediente']?.dispose();
    }
    for (var step in _instructionSteps) {
      (step['text'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ==== SUBIDA REAL A SUPABASE ====
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No estás autenticado.');

      // Extraer y procesar ingredientes
      final List<String> formattedIngredients = [];
      for (var row in _ingredientRows) {
        final cantidad = row['cantidad']?.text.trim() ?? '';
        final ingrediente = row['ingrediente']?.text.trim() ?? '';
        
        // Filtrar filas completamente vacías
        if (cantidad.isNotEmpty || ingrediente.isNotEmpty) {
          final ingredientString = cantidad.isNotEmpty && ingrediente.isNotEmpty
              ? '$cantidad - $ingrediente'
              : (cantidad.isNotEmpty ? cantidad : ingrediente);
          formattedIngredients.add(ingredientString);
        }
      }

      if (formattedIngredients.isEmpty) {
        throw Exception('Debes agregar al menos un ingrediente válido.');
      }

      final List<String> instructions = [];
      for (int i = 0; i < _instructionSteps.length; i++) {
        final step = _instructionSteps[i];
        final text = (step['text'] as TextEditingController).text.trim();
        if (text.isNotEmpty) {
          String? stepImageUrl;
          final XFile? stepImage = step['image'] as XFile?;
          
          if (stepImage != null) {
            final storage = Supabase.instance.client.storage.from('recipe_images');
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_step_${i}_${stepImage.name}';
            final filePath = '$userId/$fileName';
            
            if (kIsWeb) {
              final bytes = await stepImage.readAsBytes();
              await storage.uploadBinary(
                filePath,
                bytes,
                fileOptions: FileOptions(cacheControl: '3600', upsert: false, contentType: stepImage.mimeType ?? 'image/jpeg'),
              );
            } else {
              await storage.upload(
                filePath,
                File(stepImage.path),
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
            }
            stepImageUrl = storage.getPublicUrl(filePath);
          }
          
          final jsonString = jsonEncode({
            'text': text,
            if (stepImageUrl != null) 'imageUrl': stepImageUrl,
          });
          instructions.add(jsonString);
        }
      }

      if (instructions.isEmpty) throw Exception('Debes agregar al menos un paso de instrucción.');

      List<String> mediaUrls = [];
      
      // Subir imágenes si hay seleccionadas
      if (_selectedImages.isNotEmpty) {
        final storage = Supabase.instance.client.storage.from('recipe_images');
        
        for (final image in _selectedImages) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          final filePath = '$userId/$fileName';
          
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            await storage.uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(cacheControl: '3600', upsert: false, contentType: image.mimeType ?? 'image/jpeg'),
            );
          } else {
            await storage.upload(
              filePath,
              File(image.path),
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
          }
          
          final publicUrl = storage.getPublicUrl(filePath);
          mediaUrls.add(publicUrl);
        }
      }

      await ref.read(recipeRepositoryProvider).createRecipe(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ingredients: formattedIngredients,
        instructions: instructions,
        prepTimeMinutes: int.tryParse(_prepTimeController.text),
        servings: int.tryParse(_servingsController.text),
        category: _selectedCategory,
        mediaUrls: mediaUrls.isEmpty ? null : mediaUrls,
      );

      if (!mounted) return;

      // Refrescar el feed para que aparezca la nueva receta
      ref.refresh(filteredFeedRecipesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Receta publicada con éxito! 🎉', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Receta'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Título de la receta *',
              theme: theme,
              validator: (val) => val == null || val.isEmpty ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            
            // Image Picker Section
            Text('Imágenes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(_selectedImages[index].path) as ImageProvider
                                  : FileImage(File(_selectedImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Añadir imágenes'),
            ),
            
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción breve (opcional)',
              theme: theme,
              maxLines: 2,
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
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _prepTimeController,
                    label: 'Tiempo (min)',
                    theme: theme,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _servingsController,
                    label: 'Porciones',
                    theme: theme,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Ingredientes *', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            
            // Dynamic Ingredient Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientRows.length,
              itemBuilder: (context, index) {
                final row = _ingredientRows[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cantidad
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row['cantidad'],
                          decoration: InputDecoration(
                            labelText: 'Cant. (ej: 200g)',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.mic),
                              iconSize: 28,
                              onPressed: () => _startListening(row['cantidad']!),
                              tooltip: 'Dictar cantidad',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ingrediente
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: row['ingrediente'],
                          decoration: InputDecoration(
                            labelText: 'Ingrediente (ej: zapallo)',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.mic),
                              iconSize: 28,
                              onPressed: () => _startListening(row['ingrediente']!),
                              tooltip: 'Dictar ingrediente',
                            ),
                          ),
                        ),
                      ),
                      // Basurero
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 28,
                        onPressed: () => _removeIngredientRow(index),
                        tooltip: 'Eliminar fila',
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Botón Añadir Ingrediente
            if (_ingredientRows.length < 20)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: OutlinedButton.icon(
                  onPressed: _addIngredientRow,
                  icon: const Icon(Icons.add),
                  label: const Text('+ Añadir otro ingrediente', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            Text('Instrucciones *', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Agrega paso a paso. Puedes incluir una imagen opcional en cada uno (Máx. 20 pasos).',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _instructionSteps.length,
              itemBuilder: (context, index) {
                final step = _instructionSteps[index];
                final textController = step['text'] as TextEditingController;
                final image = step['image'] as XFile?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Paso ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeInstructionStep(index),
                              tooltip: 'Eliminar paso',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: textController,
                          maxLines: 4,
                          validator: (val) => val == null || val.trim().isEmpty ? 'El paso no puede estar vacío' : null,
                          decoration: InputDecoration(
                            labelText: 'Describe este paso...',
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.mic),
                              onPressed: () => _startListening(textController),
                              tooltip: 'Dictar paso',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (image != null)
                          Stack(
                            children: [
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(image.path) as ImageProvider
                                        : FileImage(File(image.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImageForInstruction(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => _pickImageForInstruction(index),
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Agregar imagen (opcional)'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            if (_instructionSteps.length < 20)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OutlinedButton.icon(
                  onPressed: _addInstructionStep,
                  icon: const Icon(Icons.add),
                  label: const Text('+ Añadir otro paso', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('PUBLICAR RECETA'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
