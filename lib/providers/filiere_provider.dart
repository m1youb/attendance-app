import 'package:flutter/material.dart';
import '../models/filiere.dart';
import '../services/api_service.dart';

class FiliereProvider extends ChangeNotifier {
  List<Filiere> _filieres = [];
  bool _loading = false;

  List<Filiere> get filieres => _filieres;
  bool get loading => _loading;

  String nomById(int id) => _filieres
      .firstWhere(
        (f) => f.idFiliere == id,
        orElse: () => Filiere(idFiliere: id, nomFiliere: '?'),
      )
      .nomFiliere;

  Future<void> load(String token) async {
    _loading = true;
    notifyListeners();
    try {
      _filieres = await ApiService.getFilieres(token);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(String token, String nom) async {
    await ApiService.createFiliere(token, nom);
    await load(token);
  }
}
