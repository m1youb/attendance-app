import 'package:flutter/material.dart';
import '../models/etudiant.dart';
import '../services/api_service.dart';

class EtudiantProvider extends ChangeNotifier {
  List<Etudiant> _etudiants = [];
  bool _loading = false;

  List<Etudiant> get etudiants => _etudiants;
  bool get loading => _loading;

  List<Etudiant> byFiliere(int idFiliere) =>
      _etudiants.where((e) => e.idFiliere == idFiliere).toList();

  Future<void> load(String token) async {
    _loading = true;
    notifyListeners();
    try {
      _etudiants = await ApiService.getEtudiants(token);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(
      String token, String nom, String prenom, int idFiliere) async {
    await ApiService.createEtudiant(token, nom, prenom, idFiliere);
    await load(token);
  }

  Future<void> update(
      String token, int id, String nom, String prenom, int idFiliere) async {
    await ApiService.updateEtudiant(token, id, nom, prenom, idFiliere);
    await load(token);
  }

  Future<void> delete(String token, int id) async {
    await ApiService.deleteEtudiant(token, id);
    await load(token);
  }
}
