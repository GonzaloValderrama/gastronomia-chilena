import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastronomia_chilena/features/recipes/domain/recipe.dart';
import 'package:gastronomia_chilena/features/recipes/presentation/recipe_provider.dart';
import 'package:gastronomia_chilena/features/recipes/presentation/create_recipe_screen.dart';
import 'package:gastronomia_chilena/features/social/presentation/recipe_detail_screen.dart';

class UserRecipesScreen extends ConsumerWidget {
  const UserRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userRecipesAsync = ref.watch(userRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recetas'),
        centerTitle: true,
      ),
      body: userRecipesAsync.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 24),
                    Text(
                      'Aún no has subido ninguna receta.',
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
                        ).then((_) {
                          // ignore: unused_result
                          ref.refresh(userRecipesProvider);
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear mi primera receta'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(userRecipesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildUserRecipeCard(theme, recipe, context),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error al cargar tus recetas: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(userRecipesProvider);
                },
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRecipeCard(ThemeData theme, Recipe recipe, BuildContext context) {
    return Card(
      elevation: 3,
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
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                image: (recipe.mediaUrls != null && recipe.mediaUrls!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(recipe.mediaUrls!.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (recipe.mediaUrls == null || recipe.mediaUrls!.isEmpty)
                  ? const Icon(Icons.image, size: 40, color: Colors.white54)
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepTimeMinutes ?? '--'} min',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            recipe.category ?? 'General',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
