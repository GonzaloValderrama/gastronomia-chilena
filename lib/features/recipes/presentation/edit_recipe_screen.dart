import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gastronomia_chilena/features/recipes/domain/recipe.dart';
import 'recipe_provider.dart';

class EditRecipeScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _servingsController;

  late String _selectedCategory;
  final List<String> _categories = ['General', 'Comida caliente', 'Comida fría', 'Repostería'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description ?? '');
    _ingredientsController = TextEditingController(text: widget.recipe.ingredients.join('\n'));
    _instructionsController = TextEditingController(text: widget.recipe.instructions.join('\n'));
    _prepTimeController = TextEditingController(text: widget.recipe.prepTimeMinutes?.toString() ?? '');
    _servingsController = TextEditingController(text: widget.recipe.servings?.toString() ?? '');
    _selectedCategory = widget.recipe.category ?? 'General';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'General';
    }
  }

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

  Future<void> _submit() async {
    if (widget.recipe.editCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has alcanzado el límite máximo de 3 ediciones para esta receta.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No estás autenticado.');

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

      await ref.read(recipeRepositoryProvider).updateRecipe(
        widget.recipe.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ingredients: ingredients,
        instructions: instructions,
        prepTimeMinutes: int.tryParse(_prepTimeController.text),
        servings: int.tryParse(_servingsController.text),
        category: _selectedCategory,
      );

      if (!mounted) return;

      // Refrescar vistas
      // ignore: unused_result
      ref.refresh(feedRecipesProvider);
      // ignore: unused_result
      ref.refresh(userRecipesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Receta actualizada con éxito! 🎉', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Volver a la pantalla anterior dos veces (para salir del detalle y la edición, o simplemente salir de la edición)
      // Como esto se abre sobre RecipeDetailScreen, pop nos devuelve allí
      Navigator.pop(context, true); 
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
    final isLimitReached = widget.recipe.editCount >= 3;
    final editsRemaining = 3 - widget.recipe.editCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Receta'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Banner de límite de edición
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLimitReached ? Colors.red.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLimitReached ? Colors.red : Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(
                    isLimitReached ? Icons.warning : Icons.info_outline,
                    color: isLimitReached ? Colors.red : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isLimitReached 
                          ? 'Has alcanzado el límite de 3 ediciones. No puedes modificar esta receta.'
                          : 'Puedes editar esta receta $editsRemaining ${editsRemaining == 1 ? 'vez' : 'veces'} más.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLimitReached ? Colors.red.shade900 : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _titleController,
              label: 'Título de la receta *',
              theme: theme,
              enabled: !isLimitReached,
              validator: (val) => val == null || val.isEmpty ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción breve (opcional)',
              theme: theme,
              maxLines: 2,
              enabled: !isLimitReached,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: isLimitReached ? null : (val) => setState(() => _selectedCategory = val!),
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
                    enabled: !isLimitReached,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _servingsController,
                    label: 'Porciones',
                    theme: theme,
                    keyboardType: TextInputType.number,
                    enabled: !isLimitReached,
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
              enabled: !isLimitReached,
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
              enabled: !isLimitReached,
              validator: (val) => val == null || val.isEmpty ? 'Debes agregar las instrucciones' : null,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: isLimitReached ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('GUARDAR CAMBIOS'),
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
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
