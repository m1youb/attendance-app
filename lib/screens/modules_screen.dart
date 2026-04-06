import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../models/module.dart';
import '../theme/app_theme.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<ModuleProvider>().load(token);
  }

  void _showForm({Module? existing}) {
    final ctrl = TextEditingController(text: existing?.nomModule ?? '');
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
            Text(
              existing == null ? 'Ajouter un module' : 'Modifier le module',
              style: const TextStyle(
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
                labelText: 'Nom du module',
                prefixIcon: Icon(Icons.menu_book_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.isEmpty) return;
                final token = context.read<AuthProvider>().token!;
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await context
                        .read<ModuleProvider>()
                        .create(token, ctrl.text.trim());
                  } else {
                    await context
                        .read<ModuleProvider>()
                        .update(token, existing.idModule, ctrl.text.trim());
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Module m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${m.nomModule}" ?'),
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
          .read<ModuleProvider>()
          .delete(context.read<AuthProvider>().token!, m.idModule);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moduleProvider = context.watch<ModuleProvider>();
    final modules = moduleProvider.modules;

    // Color cycle for module icons
    final colors = [
      AppColors.primary,
      AppColors.present,
      AppColors.retard,
      AppColors.justifie,
      AppColors.absent,
    ];
    final lightColors = [
      AppColors.primaryLight,
      AppColors.presentLight,
      AppColors.retardLight,
      AppColors.justifieLight,
      AppColors.absentLight,
    ];

    return Scaffold(
      body: moduleProvider.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : modules.isEmpty
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
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text('Aucun module',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Ajoutez votre premier module',
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
                    itemCount: modules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = modules[i];
                      final color = colors[i % colors.length];
                      final lightColor = lightColors[i % lightColors.length];
                      return Container(
                        decoration: cardDecoration(),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                              14, 6, 8, 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: lightColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: color, size: 22),
                          ),
                          title: Text(
                            m.nomModule,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primary, size: 20),
                                onPressed: () => _showForm(existing: m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.absent, size: 20),
                                onPressed: () => _delete(m),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
