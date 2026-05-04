import 'package:flutter/material.dart';
import 'filtered_recipes_screen.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Categorías principales
    final categories = [
      {'title': 'General', 'icon': Icons.restaurant_menu},
      {'title': 'Comida caliente', 'icon': Icons.local_fire_department},
      {'title': 'Comida fría', 'icon': Icons.ac_unit},
      {'title': 'Repostería', 'icon': Icons.cake},
    ];

    // Abecedario con Ñ
    final letters = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','Q','R','S','T','U','V','W','X','Y','Z'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diccionario y Categorías'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Sección de Categorías
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Categorías',
                style: theme.textTheme.displaySmall,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categories[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FilteredRecipesScreen(
                              filterType: FilterType.category,
                              filterValue: cat['title'] as String,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            cat['title'] as String,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
          
          // Sección del Diccionario A-Z
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Text(
                'Diccionario A-Z',
                style: theme.textTheme.displaySmall,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final letter = letters[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilteredRecipesScreen(
                            filterType: FilterType.letter,
                            filterValue: letter,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                  );
                },
                childCount: letters.length,
              ),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}
