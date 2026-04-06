import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/etudiant_provider.dart';
import '../providers/filiere_provider.dart';
import '../models/etudiant.dart';
import '../models/filiere.dart';
import '../theme/app_theme.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<EtudiantProvider>().load(token);
  }

  void _showForm({Etudiant? existing}) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final prenomCtrl = TextEditingController(text: existing?.prenom ?? '');
    final filieres = context.read<FiliereProvider>().filieres;
    Filiere? selected = existing != null
        ? filieres.firstWhere(
            (f) => f.idFiliere == existing.idFiliere,
            orElse: () =>
                filieres.isNotEmpty ? filieres.first : Filiere(idFiliere: -1, nomFiliere: ''),
          )
        : (filieres.isNotEmpty ? filieres.first : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existing == null
                    ? 'Ajouter un \u00e9tudiant'
                    : 'Modifier l\'\u00e9tudiant',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prenomCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Pr\u00e9nom'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: cardDecoration(radius: 12),
                child: DropdownButtonFormField<Filiere>(
                  value: selected,
                  decoration: const InputDecoration(
                    hintText: 'Fili\u00e8re',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: false,
                    prefixIcon: Icon(Icons.school_outlined,
                        color: AppColors.textSecondary),
                  ),
                  items: filieres
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text(f.nomFiliere)))
                      .toList(),
                  onChanged: (v) => setModal(() => selected = v),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (nomCtrl.text.isEmpty ||
                      prenomCtrl.text.isEmpty ||
                      selected == null) return;
                  final token = context.read<AuthProvider>().token!;
                  Navigator.pop(ctx);
                  try {
                    if (existing == null) {
                      await context.read<EtudiantProvider>().create(
                            token,
                            nomCtrl.text.trim(),
                            prenomCtrl.text.trim(),
                            selected!.idFiliere,
                          );
                    } else {
                      await context.read<EtudiantProvider>().update(
                            token,
                            existing.idEtudiant,
                            nomCtrl.text.trim(),
                            prenomCtrl.text.trim(),
                            selected!.idFiliere,
                          );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Etudiant e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?'),
        content: Text('Supprimer ${e.prenom} ${e.nom} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.absent,
                minimumSize: const Size(0, 40)),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await context
          .read<EtudiantProvider>()
          .delete(context.read<AuthProvider>().token!, e.idEtudiant);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final etudiantProvider = context.watch<EtudiantProvider>();
    final filiereProvider = context.watch<FiliereProvider>();
    final etudiants = etudiantProvider.etudiants;

    return Scaffold(
      body: etudiantProvider.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : etudiants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.people_rounded,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text('Aucun \u00e9tudiant',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Ajoutez votre premier \u00e9tudiant',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: etudiants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = etudiants[i];
                      final initials =
                          '${e.prenom.isNotEmpty ? e.prenom[0] : ''}${e.nom.isNotEmpty ? e.nom[0] : ''}'
                              .toUpperCase();
                      return Container(
                        decoration: cardDecoration(),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                              14, 6, 8, 6),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(initials,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(
                            '${e.prenom} ${e.nom}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            filiereProvider.nomById(e.idFiliere),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primary, size: 20),
                                onPressed: () => _showForm(existing: e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.absent, size: 20),
                                onPressed: () => _delete(e),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
