import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _locale = const Locale('ro'); // Default to Romanian
  
  Locale get locale => _locale;
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('ro'), // Romanian
    Locale('en'), // English
    Locale('de'), // German
  ];
  
  // Language names for display
  static const Map<String, String> languageNames = {
    'ro': 'Română',
    'en': 'English',
    'de': 'Deutsch',
  };
  
  // Initialize language from stored preferences
  Future<void> initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      final supportedLanguage = supportedLocales.firstWhere(
        (locale) => locale.languageCode == languageCode,
        orElse: () => const Locale('ro'),
      );
      _locale = supportedLanguage;
      notifyListeners();
    }
  }
  
  // Change language
  Future<void> changeLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    
    if (supportedLocales.contains(newLocale)) {
      _locale = newLocale;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    }
  }
  
  // Get language name for display
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
  
  // Check if locale is supported
  bool isSupported(Locale locale) {
    return supportedLocales.contains(locale);
  }
}
