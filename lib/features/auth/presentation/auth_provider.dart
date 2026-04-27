import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

// Provider global para el repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// StreamProvider para escuchar los cambios de sesión
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Provider para el usuario actual
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
});
