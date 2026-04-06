import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/filiere_provider.dart';
import '../theme/app_theme.dart';

class FilieresScreen extends StatefulWidget {
  const FilieresScreen({super.key});

  @override
  State<FilieresScreen> createState() => _FilieresScreenState();
}

class _FilieresScreenState extends State<FilieresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<FiliereProvider>().load(token);
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            const Text(
              'Ajouter une fili\u00e8re',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nom de la fili\u00e8re',
                prefixIcon:
                    Icon(Icons.school_outlined, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.isEmpty) return;
                final token = context.read<AuthProvider>().token!;
                Navigator.pop(ctx);
                try {
                  await context
                      .read<FiliereProvider>()
                      .create(token, ctrl.text.trim());
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filiereProvider = context.watch<FiliereProvider>();
    final filieres = filiereProvider.filieres;

    return Scaffold(
      appBar: AppBar(title: const Text('Fili\u00e8res')),
      backgroundColor: AppColors.background,
      body: filiereProvider.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : filieres.isEmpty
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
                        child: const Icon(Icons.school_rounded,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text('Aucune fili\u00e8re',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Ajoutez votre premi\u00e8re fili\u00e8re',
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
                    itemCount: filieres.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final f = filieres[i];
                      return Container(
                        decoration: cardDecoration(),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                              14, 8, 14, 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: AppColors.primary),
                          ),
                          title: Text(
                            f.nomFiliere,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 15),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${f.idFiliere}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
