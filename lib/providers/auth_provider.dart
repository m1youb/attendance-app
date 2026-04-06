import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/professeur.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Professeur? _professeur;
  bool _loading = false;

  String? get token => _token;
  Professeur? get professeur => _professeur;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null && _professeur != null;
  int? get profId => _professeur?.idProf;

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('token');
    if (saved == null) return;
    try {
      final prof = await ApiService.getMe(saved);
      _token = saved;
      _professeur = prof;
      notifyListeners();
    } catch (_) {
      await prefs.remove('token');
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final t = await ApiService.login(email, password);
      final prof = await ApiService.getMe(t);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', t);
      _token = t;
      _professeur = prof;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _professeur = null;
    notifyListeners();
  }
}
