import 'package:flutter/material.dart';
import '../models/seance.dart';
import '../services/api_service.dart';

class SeanceProvider extends ChangeNotifier {
  List<Seance> _seances = [];
  bool _loading = false;

  List<Seance> get seances => _seances;
  bool get loading => _loading;

  List<Seance> mySeances(int profId) {
    final list = _seances.where((s) => s.idProf == profId).toList();
    list.sort((a, b) => b.dateSeance.compareTo(a.dateSeance));
    return list;
  }

  Future<void> load(String token) async {
    _loading = true;
    notifyListeners();
    try {
      _seances = await ApiService.getSeances(token);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(
    String token,
    String dateSeance,
    String heureDebut,
    String heureFin,
    int idModule,
    int idFiliere,
  ) async {
    await ApiService.createSeance(
        token, dateSeance, heureDebut, heureFin, idModule, idFiliere);
    await load(token);
  }
}
