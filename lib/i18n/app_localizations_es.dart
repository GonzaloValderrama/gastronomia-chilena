// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gastronomía a la Chilena';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get searchPlaceholder => 'Buscar receta o ingrediente...';
}

/// The translations for Spanish Castilian, as used in Chile (`es_CL`).
class AppLocalizationsEsCl extends AppLocalizationsEs {
  AppLocalizationsEsCl() : super('es_CL');

  @override
  String get appTitle => 'Gastronomía a la Chilena';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get searchPlaceholder => 'Buscar receta o ingrediente...';
}
