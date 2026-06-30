import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  static const _key = 'app_language';

  LanguageNotifier() : super('fr') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key);
    if (lang != null) {
      state = lang;
    }
  }

  Future<void> toggleLanguage() async {
    final newLang = state == 'fr' ? 'en' : 'fr';
    state = newLang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newLang);
  }
}
