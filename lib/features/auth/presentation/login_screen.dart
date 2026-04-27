import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);
    try {
      if (_isRegistering) {
        await authRepo.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          'Nuevo Usuario', // Podría expandirse para pedir el nombre
        );
        _showMessage('Registro exitoso. Revisa tu correo.', isError: false);
      } else {
        await authRepo.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Ingresa tu correo para recuperar la contraseña', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(_emailController.text.trim());
      _showMessage('Correo de recuperación enviado', isError: false);
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 18), // Texto grande en SnackBar
        ),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Crear Cuenta' : 'Iniciar Sesión'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campos de texto grandes y legibles
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isRegistering ? 'Registrarse' : 'Ingresar'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _isRegistering = !_isRegistering);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56), // Touch target grande
                      ),
                      child: Text(
                        _isRegistering 
                            ? '¿Ya tienes cuenta? Inicia sesión' 
                            : '¿No tienes cuenta? Regístrate',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    if (!_isRegistering) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _resetPassword,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Text(
                          'Olvidé mi contraseña',
                          style: theme.textTheme.labelLarge?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 48, thickness: 2),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text('Entrar con Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => ref.read(authRepositoryProvider).signInWithGoogle(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.facebook, size: 28),
                      label: const Text('Entrar con Facebook'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => ref.read(authRepositoryProvider).signInWithFacebook(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
