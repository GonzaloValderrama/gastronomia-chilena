import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final userName = currentUser?.userMetadata?['full_name'] as String? ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes y Accesibilidad'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Hola $userName',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tema Visual',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          _buildThemeTile(
            context,
            ref,
            title: 'Claro',
            mode: AppThemeMode.light,
            currentMode: currentTheme,
            icon: Icons.light_mode,
          ),
          _buildThemeTile(
            context,
            ref,
            title: 'Oscuro',
            mode: AppThemeMode.dark,
            currentMode: currentTheme,
            icon: Icons.dark_mode,
          ),
          _buildThemeTile(
            context,
            ref,
            title: 'Rústico Chileno',
            mode: AppThemeMode.rustic,
            currentMode: currentTheme,
            icon: Icons.cabin,
          ),
          _buildThemeTile(
            context,
            ref,
            title: 'Alto Contraste',
            mode: AppThemeMode.highContrast,
            currentMode: currentTheme,
            icon: Icons.contrast,
          ),
          const Divider(height: 48, thickness: 2),
          Text(
            'Cuenta',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Sesión iniciada como: $userName',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            currentUser?.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required AppThemeMode mode,
    required AppThemeMode currentMode,
    required IconData icon,
  }) {
    final isSelected = mode == currentMode;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => ref.read(themeProvider.notifier).changeTheme(mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Padding grande para accesibilidad
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
