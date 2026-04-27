import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración'),
          backgroundColor: Colors.blueGrey, // Color distinto para área admin
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Contenido Reportado'),
              Tab(text: 'Palabras Prohibidas'),
            ],
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportedContentTab(theme),
            _buildBannedWordsTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildReportedContentTab(ThemeData theme) {
    // Simulación de datos ocultos (is_hidden = true)
    final reportedItems = [
      {'type': 'Comentario', 'content': 'Este es un comentario inapropiado...', 'reports': 4},
      {'type': 'Receta', 'content': 'Receta Falsa', 'reports': 3},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: reportedItems.length,
      itemBuilder: (context, index) {
        final item = reportedItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['type'] as String, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.red)),
                    Text('${item['reports']} Reportes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['content'] as String, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Lógica: UPDATE recipes/comments SET is_hidden = false
                      },
                      child: const Text('Restaurar', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {
                        // Lógica: DELETE FROM recipes/comments
                      },
                      child: const Text('Eliminar Permanentemente', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannedWordsTab(ThemeData theme) {
    // Simulación de palabras prohibidas
    final bannedWords = ['palabrota1', 'insulto2', 'spam3'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Nueva palabra prohibida',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // Lógica: INSERT INTO banned_words
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: bannedWords.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(bannedWords[index], style: theme.textTheme.bodyLarge),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                  onPressed: () {
                    // Lógica: DELETE FROM banned_words
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
