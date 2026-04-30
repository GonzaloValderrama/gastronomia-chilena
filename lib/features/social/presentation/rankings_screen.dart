import 'package:flutter/material.dart';

class RankingsScreen extends StatelessWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Simulación de datos extraídos de la vista materializada (mv_rankings)
    final topRecipes = [
      {'title': 'Pastel de Choclo', 'author': 'Ana González', 'score': 4.9, 'comments': 120},
      {'title': 'Empanadas de Pino', 'author': 'Juan Pérez', 'score': 4.8, 'comments': 95},
      {'title': 'Cazuela de Ave', 'author': 'Marta Silva', 'score': 4.7, 'comments': 80},
      {'title': 'Mote con Huesillo', 'author': 'Pedro Reyes', 'score': 4.6, 'comments': 60},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Recetas de la Semana'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: topRecipes.length,
        itemBuilder: (context, index) {
          final recipe = topRecipes[index];
          
          // Iconos de Trofeos para los 3 primeros lugares
          Widget? trophy;
          if (index == 0) {
            trophy = const Icon(Icons.emoji_events, color: Colors.amber, size: 48); // Oro
          } else if (index == 1) trophy = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 40); // Plata
          else if (index == 2) trophy = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 40); // Bronce

          return Card(
            elevation: index < 3 ? 6 : 2, // Más relieve para el Top 3
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: index == 0 ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: SizedBox(
                width: 60,
                child: Center(
                  child: trophy ?? Text('#${index + 1}', style: theme.textTheme.headlineMedium),
                ),
              ),
              title: Text(recipe['title'] as String, style: theme.textTheme.displaySmall),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Por ${recipe['author']}', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 24),
                      Text(' ${recipe['score']}  •  ', style: const TextStyle(fontSize: 18)),
                      const Icon(Icons.comment, color: Colors.grey, size: 24),
                      Text(' ${recipe['comments']}', style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
              onTap: () {
                // Navegar a la receta
              },
            ),
          );
        },
      ),
    );
  }
}
