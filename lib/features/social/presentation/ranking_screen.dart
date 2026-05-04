import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastronomia_chilena/features/social/presentation/ranking_provider.dart';
import 'package:gastronomia_chilena/features/recipes/domain/recipe.dart';
import 'package:gastronomia_chilena/features/social/presentation/recipe_detail_screen.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ranking'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.star), text: 'Mejores Recetas'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Top Creadores'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TopRatedRecipesTab(),
            _TopContributorsTab(),
          ],
        ),
      ),
    );
  }
}

class _TopRatedRecipesTab extends ConsumerWidget {
  const _TopRatedRecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topRatedAsync = ref.watch(topRatedRecipesProvider);

    return topRatedAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return const Center(child: Text('Aún no hay recetas calificadas.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final rank = index + 1;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(rank, theme),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                title: Text(recipe['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Por ${recipe['display_name'] ?? 'Anónimo'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe['average_score'] ?? '0.0'}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text('(${recipe['rating_count'] ?? 0})', style: theme.textTheme.bodySmall),
                  ],
                ),
                onTap: () {
                  final recipeObj = Recipe(
                    id: recipe['id'] ?? '',
                    authorId: recipe['author_id'] ?? '',
                    authorName: recipe['display_name'] ?? 'Anónimo',
                    title: recipe['title'] ?? '',
                    description: null,
                    ingredients: [],
                    instructions: [],
                    mediaUrls: recipe['media_urls'] != null ? List<String>.from(recipe['media_urls']) : null,
                    isHidden: false,
                    editCount: 0,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(recipe: recipeObj),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Color _getRankColor(int rank, ThemeData theme) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    return theme.colorScheme.primary;
  }
}

class _TopContributorsTab extends ConsumerWidget {
  const _TopContributorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topContributorsAsync = ref.watch(topContributorsProvider);

    return topContributorsAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('Aún no hay creadores.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final rank = index + 1;
            final avatarUrl = user['avatar_url'] as String?;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                    if (rank <= 3)
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: _getRankColor(rank, theme),
                        child: Text(
                          '$rank',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (rank > 3)
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '$rank',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                  ],
                ),
                title: Text(user['display_name'] ?? 'Usuario Anónimo', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${user['recipe_count'] ?? 0}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                    Text('recetas', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Color _getRankColor(int rank, ThemeData theme) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    return theme.colorScheme.primary;
  }
}
