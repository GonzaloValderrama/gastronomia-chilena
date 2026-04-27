import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Iniciar sesión con Correo y Contraseña
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Registrar con Correo y Contraseña
  Future<AuthResponse> signUpWithEmail(String email, String password, String fullName) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // Enviar correo de recuperación
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Iniciar sesión con Google (OAuth)
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'cl.gastronomia://login-callback',
    );
  }

  // Iniciar sesión con Meta/Facebook (OAuth)
  Future<bool> signInWithFacebook() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'cl.gastronomia://login-callback',
    );
  }

  // Cerrar Sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;
  
  // Stream de estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
