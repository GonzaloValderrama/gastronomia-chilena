import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';

import 'features/home/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Iniciando Supabase...');
    // Inicialización de Supabase
    await Supabase.initialize(
      url: 'https://iitzgfjjlfemzanqpaet.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpdHpnZmpqbGZlbXphbnFwYWV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMTE4MjUsImV4cCI6MjA5Mjc4NzgyNX0.A6poXmBgNB2W4AcssCsR3nGbKRXD_8ELcf6DI-ynIMA',
    );
    debugPrint('Supabase inicializado correctamente.');
  } catch (e) {
    debugPrint('Error al inicializar Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: GastronomiaApp(),
    ),
  );
}

class GastronomiaApp extends ConsumerWidget {
  const GastronomiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el modo de tema actual
    final themeMode = ref.watch(themeProvider);
    
    // Configurar el tema en la app
    return MaterialApp(
      title: 'Gastronomía a la Chilena',
      theme: AppTheme.getThemeData(themeMode),
      home: const AuthWrapper(),
    );
  }
}

// Wrapper para decidir qué pantalla mostrar basado en el estado de autenticación
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    
    return authState.when(
      data: (state) {
        final session = state.session;
        if (session != null) {
          // Usuario autenticado.
          return const HomeScreen();
        } else {
          // Usuario no autenticado
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
