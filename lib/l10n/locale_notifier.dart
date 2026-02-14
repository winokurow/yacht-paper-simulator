import 'package:flutter/material.dart';

/// Хранит текущую локаль; смена языка обновляет UI через Provider.
class LocaleNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  set locale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
  }

  void setLocale(Locale value) {
    locale = value;
  }
}
