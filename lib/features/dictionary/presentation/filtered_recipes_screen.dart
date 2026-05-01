import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastronomia_chilena/features/recipes/domain/recipe.dart';
import 'package:gastronomia_chilena/features/recipes/presentation/recipe_provider.dart';
import 'package:gastronomia_chilena/features/social/presentation/recipe_detail_screen.dart';

enum FilterType { category, letter }

class FilteredRecipesScreen extends ConsumerWidget {
  final FilterType filterType;
  final String filterValue;

  const FilteredRecipesScreen({
    super.key,
    required this.filterType,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final String title = filterType == FilterType.category
        ? 'Categoría: $filterValue'
        : 'Recetas con la letra $filterValue';

    // Seleccionar el provider adecuado basado en el tipo de filtro
    final asyncRecipes = filterType == FilterType.category
        ? ref.watch(recipesByCategoryProvider(filterValue))
        : ref.watch(recipesByLetterProvider(filterValue));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: asyncRecipes.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    Text(
                      'No encontramos recetas para "$filterValue".',
                      style: theme.textTheme.displaySmall?.copyWith(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Anímate a ser el primero en publicar una!',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return _buildRecipeCard(context, recipes[index], theme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Ocurrió un error al cargar las recetas:\n$err',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen Placeholder o Real
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recipe.description != null)
                    Text(
                      recipe.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (recipe.category != null)
                        Chip(
                          label: Text(recipe.category!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                      Row(
                        children: [
                          if (recipe.prepTimeMinutes != null) ...[
                            const Icon(Icons.timer, size: 24, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('${recipe.prepTimeMinutes}m', style: theme.textTheme.bodyLarge),
                            const SizedBox(width: 16),
                          ],
                          const Icon(Icons.star, size: 24, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('4.5', style: theme.textTheme.bodyLarge), // Placeholder
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
