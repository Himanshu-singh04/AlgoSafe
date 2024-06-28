import 'package:algo_safe/constants/theme_configuration.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService{
  ThemeService._();

  static late SharedPreferences preferences;
  static ThemeService? _instance;

  static Future<ThemeService> get instance async{
    if (_instance == null){
      preferences = await SharedPreferences.getInstance();
      _instance = ThemeService._();
    }
    return _instance!;
  }

  final allThemes = <String, ThemeData>{
    'Dark' : darkTheme,
    'Light' : lightTheme
  };

  get initial {
    String? themeName = preferences.getString('theme');
    if (themeName == null){
      // ignore: deprecated_member_use
      final isPlatformDark = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      themeName = isPlatformDark ? 'Dark' : 'Light';
    }
    return allThemes[themeName];
  }

  save(String newThemeName){
    preferences.setString('theme', newThemeName);
  }

  ThemeData getByName(String name){
    return allThemes[name]!;
  }
}