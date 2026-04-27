import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _servingsController = TextEditingController();

  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Comida caliente', 'Comida fría', 'Repostería'];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  // ==== SUBIDA REAL A SUPABASE ====
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No estás autenticado.');

      // Convertir ingredientes e instrucciones de texto a listas
      final ingredients = _ingredientsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final instructions = _instructionsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (ingredients.isEmpty) throw Exception('Debes agregar al menos un ingrediente.');
      if (instructions.isEmpty) throw Exception('Debes agregar al menos un paso de instrucción.');

      await ref.read(recipeRepositoryProvider).createRecipe(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ingredients: ingredients,
        instructions: instructions,
        prepTimeMinutes: int.tryParse(_prepTimeController.text),
        servings: int.tryParse(_servingsController.text),
        category: _selectedCategory,
      );

      if (!mounted) return;

      // Refrescar el feed para que aparezca la nueva receta
      ref.refresh(feedRecipesProvider);

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
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción breve (opcional)',
              theme: theme,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
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
            const SizedBox(height: 4),
            Text(
              'Escribe cada ingrediente en una línea separada',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _ingredientsController,
              label: 'Ej:\n2 tazas de harina\n1 kilo de carne',
              theme: theme,
              maxLines: 6,
              validator: (val) => val == null || val.isEmpty ? 'Debes agregar ingredientes' : null,
            ),
            const SizedBox(height: 24),
            Text('Instrucciones *', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Escribe cada paso en una línea separada',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _instructionsController,
              label: 'Ej:\nMezclar harina con agua\nAmasar por 10 minutos',
              theme: theme,
              maxLines: 8,
              validator: (val) => val == null || val.isEmpty ? 'Debes agregar las instrucciones' : null,
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
