import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = true;

  @override
  void dispose() {
    _nameController.dispose();
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
          _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'Nuevo Usuario',
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
      _showMessage('Ingresa tu correo para recuperar la contraseña',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(_emailController.text.trim());
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
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/login_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surface.withOpacity(0.7)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Icon(
                            Icons.restaurant,
                            size: 64,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isRegistering ? 'Crear Cuenta' : 'Iniciar Sesión',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gastronomía a la Chilena',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Text Fields
                          if (_isRegistering) ...[
                            TextField(
                              controller: _nameController,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Nombre y Apellido',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.all(20),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Correo Electrónico',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                          const SizedBox(height: 32),

                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    _isRegistering ? 'REGISTRARSE' : 'INGRESAR',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(
                                        () => _isRegistering = !_isRegistering);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                        color: Colors.red.shade300, width: 2),
                                  ),
                                  child: Text(
                                    _isRegistering
                                        ? '¿Ya tienes cuenta? Inicia sesión'
                                        : '¿No tienes cuenta? Regístrate',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!_isRegistering) ...[
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _resetPassword,
                                    style: TextButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 56),
                                    ),
                                    child: Text(
                                      'Olvidé mi contraseña',
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        decoration: TextDecoration.underline,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Expanded(
                                        child: Divider(thickness: 1.5)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text('O',
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ),
                                    const Expanded(
                                        child: Divider(thickness: 1.5)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon:
                                      const Icon(Icons.g_mobiledata, size: 32),
                                  label: const Text('Entrar con Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? Colors.grey.shade800
                                        : Colors.white,
                                    foregroundColor:
                                        isDark ? Colors.white : Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () => ref
                                      .read(authRepositoryProvider)
                                      .signInWithGoogle(),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.facebook, size: 28),
                                  label: const Text('Entrar con Facebook',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1877F2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () => ref
                                      .read(authRepositoryProvider)
                                      .signInWithFacebook(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
