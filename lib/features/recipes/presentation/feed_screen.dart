import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';
import 'recipe_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipesAsyncValue = ref.watch(feedRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas a la Chilena'),
        centerTitle: true,
      ),
      body: recipesAsyncValue.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return const Center(
              child: Text('Aún no hay recetas publicadas.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(feedRecipesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: recipes.length + (recipes.length ~/ 8), // Ajuste por los anuncios (1 cada 8)
              itemBuilder: (context, index) {
                
                // Lógica para intercalar Anuncio Nativo cada 8 recetas de la comunidad
                if (index > 0 && index % 9 == 0) {
                  return _buildNativeAdCard(theme);
                }

                final recipeIndex = index - (index ~/ 9);
                final recipe = recipes[recipeIndex];

                // Sección de Destacados (Primera receta)
                if (recipeIndex == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Destacada de Hoy', style: theme.textTheme.displayMedium),
                      const SizedBox(height: 16),
                      _buildRecipeCard(theme, recipe, true),
                      const SizedBox(height: 24),
                      Text('Recetas de la Comunidad', style: theme.textTheme.displayMedium),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                // Listado estándar de la comunidad
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildRecipeCard(theme, recipe, false),
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
              Text('Error al cargar recetas: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(feedRecipesProvider);
                },
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
      // FAB para agregar receta (Paso 5)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar a pantalla de creación
        },
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Nueva Receta', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  // Tarjeta de Receta
  Widget _buildRecipeCard(ThemeData theme, Recipe recipe, bool isFeatured) {
    return Card(
      elevation: isFeatured ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navegar al detalle de receta
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: isFeatured ? 200 : 140,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: (recipe.mediaUrls != null && recipe.mediaUrls!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(recipe.mediaUrls!.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (recipe.mediaUrls == null || recipe.mediaUrls!.isEmpty)
                  ? const Icon(Icons.image, size: 64, color: Colors.white54)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: isFeatured ? theme.textTheme.displaySmall : theme.textTheme.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (recipe.description != null)
                    Text(
                      recipe.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 24),
                      const SizedBox(width: 4),
                      Text('${recipe.prepTimeMinutes ?? '--'} min', style: theme.textTheme.bodyLarge),
                      const SizedBox(width: 24),
                      const Icon(Icons.star, size: 24, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('4.8', style: theme.textTheme.bodyLarge),
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

  // Tarjeta de Anuncio Nativo Diferenciada
  Widget _buildNativeAdCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Publicidad', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 100, // Espacio reservado para el NativeAd de Google AdMob
              child: Center(
                child: Text('Espacio para Google Native Ad', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
