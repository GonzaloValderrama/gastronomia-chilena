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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Recetas'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recetas Creadas', icon: Icon(Icons.book)),
              Tab(text: 'Favoritas', icon: Icon(Icons.favorite)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CreatedRecipesTab(),
            _FavoriteRecipesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
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
          label: const Text('Nueva Receta'),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _CreatedRecipesTab extends ConsumerWidget {
  const _CreatedRecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userRecipesAsync = ref.watch(userRecipesProvider);

    return userRecipesAsync.when(
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
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 80.0),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _RecipeCard(recipe: recipe),
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
    );
  }
}

class _FavoriteRecipesTab extends ConsumerWidget {
  const _FavoriteRecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favoriteRecipesAsync = ref.watch(favoriteRecipesProvider);

    return favoriteRecipesAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 24),
                  Text(
                    'Aún no tienes recetas favoritas.',
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // ignore: unused_result
            ref.refresh(favoriteRecipesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 80.0),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _RecipeCard(recipe: recipe),
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
            Text('Error al cargar favoritas: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(favoriteRecipesProvider);
              },
              child: const Text('Reintentar'),
            )
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
