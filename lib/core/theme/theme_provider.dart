import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

// Este StateNotifier mantendrá el estado del tema de la aplicación.
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.rustic);

  void changeTheme(AppThemeMode mode) {
    state = mode;
  }
}

// Provider global para exponer el ThemeNotifier a la interfaz de usuario.
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
