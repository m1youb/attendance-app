import 'package:flutter/material.dart';
import '../models/module.dart';
import '../services/api_service.dart';

class ModuleProvider extends ChangeNotifier {
  List<Module> _modules = [];
  bool _loading = false;

  List<Module> get modules => _modules;
  bool get loading => _loading;

  String nomById(int id) => _modules
      .firstWhere(
        (m) => m.idModule == id,
        orElse: () => Module(idModule: id, nomModule: '?'),
      )
      .nomModule;

  Future<void> load(String token) async {
    _loading = true;
    notifyListeners();
    try {
      _modules = await ApiService.getModules(token);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(String token, String nom) async {
    await ApiService.createModule(token, nom);
    await load(token);
  }

  Future<void> update(String token, int id, String nom) async {
    await ApiService.updateModule(token, id, nom);
    await load(token);
  }

  Future<void> delete(String token, int id) async {
    await ApiService.deleteModule(token, id);
    await load(token);
  }
}
