import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastronomia_chilena/features/recipes/domain/recipe.dart';
import 'package:gastronomia_chilena/features/recipes/presentation/recipe_provider.dart';
import 'package:gastronomia_chilena/features/social/presentation/recipe_detail_screen.dart';
import 'package:gastronomia_chilena/features/settings/presentation/settings_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipesAsyncValue = ref.watch(filteredFeedRecipesProvider);
    final currentCategory = ref.watch(feedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas a la Chilena'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
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
              ref.refresh(filteredFeedRecipesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Barra de Búsqueda
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar recetas...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(feedSearchQueryProvider.notifier).state = '';
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (value) {
                      ref.read(feedSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                // Chips de Filtro
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todas', 'General', 'Comida caliente', 'Comida fría', 'Repostería'].map((category) {
                      final isSelected = category == currentCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              ref.read(feedCategoryProvider.notifier).state = category;
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Receta Destacada
                Text('Destacada de Hoy', style: theme.textTheme.displayMedium),
                const SizedBox(height: 16),
                _buildRecipeCard(theme, recipes.first, true),
                
                const SizedBox(height: 32),
                
                // Recetas de la Comunidad (Carrusel)
                Text('Recetas de la Comunidad', style: theme.textTheme.displayMedium),
                const SizedBox(height: 16),
                
                if (recipes.length > 1)
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.length - 1,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index + 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: SizedBox(
                            width: 240,
                            child: _buildRecipeCard(theme, recipe, false),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Icon(Icons.soup_kitchen, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay recetas aquí.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
              ],
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
                  ref.refresh(filteredFeedRecipesProvider);
                },
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de Receta
  Widget _buildRecipeCard(ThemeData theme, Recipe recipe, bool isFeatured) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
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
              Stack(
                children: [
                  Container(
                    height: isFeatured ? 200 : 140,
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
                        ? const Center(child: Icon(Icons.image, size: 64, color: Colors.white54))
                        : null,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteButton(recipe: recipe),
                  ),
                ],
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
                    if (recipe.description != null && isFeatured)
                      Text(
                        recipe.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isFeatured) const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 18),
                        const SizedBox(width: 4),
                        Text('${recipe.prepTimeMinutes ?? '--'} min', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 18, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('4.8', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            recipe.authorName != null 
                                ? '👤 ${recipe.authorName}' 
                                : '👤 Anónimo',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _FavoriteButton extends ConsumerWidget {
  final Recipe recipe;
  
  const _FavoriteButton({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavoriteAsync = ref.watch(isFavoriteRecipeProvider(recipe.id));

    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white70,
      ),
      child: IconButton(
        icon: isFavoriteAsync.when(
          data: (isFavorite) => Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
          loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Icon(Icons.favorite_border, color: Colors.grey),
        ),
        onPressed: () async {
          final isFav = isFavoriteAsync.valueOrNull ?? false;
          final repo = ref.read(recipeRepositoryProvider);
          try {
            await repo.toggleFavorite(recipe.id, !isFav);
            ref.invalidate(isFavoriteRecipeProvider(recipe.id));
            ref.invalidate(favoriteRecipesProvider);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }
}
