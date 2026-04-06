import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/professeur.dart';
import '../models/filiere.dart';
import '../models/module.dart';
import '../models/etudiant.dart';
import '../models/seance.dart';
import '../models/presence.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _base = AppConfig.baseUrl;

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static void _check(http.Response res) {
    if (res.statusCode >= 400) {
      String msg = 'Erreur ${res.statusCode}';
      try {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (body['detail'] != null) msg = body['detail'].toString();
      } catch (_) {}
      throw ApiException(msg);
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<String> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    _check(res);
    return jsonDecode(utf8.decode(res.bodyBytes))['access_token'] as String;
  }

  static Future<Professeur> getMe(String token) async {
    final res = await http.get(
      Uri.parse('$_base/me'),
      headers: _authHeaders(token),
    );
    _check(res);
    return Professeur.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  // ── Filieres ──────────────────────────────────────────────────────────────

  static Future<List<Filiere>> getFilieres(String token) async {
    final res = await http.get(
      Uri.parse('$_base/filieres'),
      headers: _authHeaders(token),
    );
    _check(res);
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => Filiere.fromJson(e))
        .toList();
  }

  static Future<void> createFiliere(String token, String nom) async {
    final res = await http.post(
      Uri.parse('$_base/filieres?nom=${Uri.encodeComponent(nom)}'),
      headers: _authHeaders(token),
    );
    _check(res);
  }

  // ── Modules ───────────────────────────────────────────────────────────────

  static Future<List<Module>> getModules(String token) async {
    final res = await http.get(
      Uri.parse('$_base/modules'),
      headers: _authHeaders(token),
    );
    _check(res);
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => Module.fromJson(e))
        .toList();
  }

  static Future<void> createModule(String token, String nom) async {
    final res = await http.post(
      Uri.parse('$_base/modules'),
      headers: _authHeaders(token),
      body: jsonEncode({'nom_module': nom}),
    );
    _check(res);
  }

  static Future<void> updateModule(String token, int id, String nom) async {
    final res = await http.put(
      Uri.parse('$_base/modules/$id'),
      headers: _authHeaders(token),
      body: jsonEncode({'nom_module': nom}),
    );
    _check(res);
  }

  static Future<void> deleteModule(String token, int id) async {
    final res = await http.delete(
      Uri.parse('$_base/modules/$id'),
      headers: _authHeaders(token),
    );
    _check(res);
  }

  // ── Etudiants ─────────────────────────────────────────────────────────────

  static Future<List<Etudiant>> getEtudiants(String token) async {
    final res = await http.get(
      Uri.parse('$_base/etudiants'),
      headers: _authHeaders(token),
    );
    _check(res);
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => Etudiant.fromJson(e))
        .toList();
  }

  static Future<void> createEtudiant(
      String token, String nom, String prenom, int idFiliere) async {
    final res = await http.post(
      Uri.parse('$_base/etudiants'),
      headers: _authHeaders(token),
      body: jsonEncode({'nom': nom, 'prenom': prenom, 'id_filiere': idFiliere}),
    );
    _check(res);
  }

  static Future<void> updateEtudiant(
      String token, int id, String nom, String prenom, int idFiliere) async {
    final res = await http.put(
      Uri.parse('$_base/etudiants/$id'),
      headers: _authHeaders(token),
      body: jsonEncode({'nom': nom, 'prenom': prenom, 'id_filiere': idFiliere}),
    );
    _check(res);
  }

  static Future<void> deleteEtudiant(String token, int id) async {
    final res = await http.delete(
      Uri.parse('$_base/etudiants/$id'),
      headers: _authHeaders(token),
    );
    _check(res);
  }

  // ── Seances ───────────────────────────────────────────────────────────────

  static Future<List<Seance>> getSeances(String token) async {
    final res = await http.get(
      Uri.parse('$_base/seances'),
      headers: _authHeaders(token),
    );
    _check(res);
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => Seance.fromJson(e))
        .toList();
  }

  static Future<void> createSeance(
    String token,
    String dateSeance,
    String heureDebut,
    String heureFin,
    int idModule,
    int idFiliere,
  ) async {
    final res = await http.post(
      Uri.parse('$_base/seances'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'date_seance': dateSeance,
        'heure_debut': heureDebut,
        'heure_fin': heureFin,
        'id_module': idModule,
        'id_filiere': idFiliere,
      }),
    );
    _check(res);
  }

  // ── Presences ─────────────────────────────────────────────────────────────

  static Future<List<Presence>> getPresences(String token, int idSeance) async {
    final res = await http.get(
      Uri.parse('$_base/presences?id_seance=$idSeance'),
      headers: _authHeaders(token),
    );
    _check(res);
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => Presence.fromJson(e))
        .toList();
  }

  static Future<void> submitPresences(
    String token,
    int idSeance,
    List<Map<String, dynamic>> records,
  ) async {
    final res = await http.post(
      Uri.parse('$_base/presences'),
      headers: _authHeaders(token),
      body: jsonEncode({'id_seance': idSeance, 'records': records}),
    );
    _check(res);
  }

  static Future<Map<String, dynamic>> getStats(String token) async {
    final res = await http.get(
      Uri.parse('$_base/presences/stats'),
      headers: _authHeaders(token),
    );
    _check(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}
