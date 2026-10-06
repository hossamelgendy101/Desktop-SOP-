import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();

  factory LocaleService() => _instance;

  LocaleService._internal();

  Locale _locale = const Locale('en');
  Map<String, String> _localizedStrings = {};
  bool _isRTL = false;

  Locale get locale => _locale;
  bool get isRTL => _isRTL;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    await setLocale(Locale(langCode));
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    _isRTL = locale.languageCode == 'ar';

    final jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);

    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String localize(String english, String arabic) {
    return locale.languageCode == 'ar' ? arabic : english;
  }
}

extension TranslateExtension on BuildContext {
  String tr(String key) {
    return LocaleService().translate(key);
  }
}
