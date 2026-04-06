import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../providers/module_provider.dart';
import '../providers/filiere_provider.dart';
import '../models/filiere.dart';
import '../models/module.dart';
import '../theme/app_theme.dart';

class CreateSeanceScreen extends StatefulWidget {
  const CreateSeanceScreen({super.key});

  @override
  State<CreateSeanceScreen> createState() => _CreateSeanceScreenState();
}

class _CreateSeanceScreenState extends State<CreateSeanceScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay _heureDebut = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 10, minute: 0);
  Filiere? _selectedFiliere;
  Module? _selectedModule;
  bool _submitting = false;
  String? _error;

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _formatDateDisplay(DateTime d) =>
      DateFormat('EEEE d MMMM yyyy', 'fr').format(d);
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isDebut) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isDebut ? _heureDebut : _heureFin,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isDebut ? _heureDebut = picked : _heureFin = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedFiliere == null || _selectedModule == null) {
      setState(() =>
          _error = 'Veuillez s\u00e9lectionner une fili\u00e8re et un module.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      await context.read<SeanceProvider>().create(
            token,
            _formatDate(_date),
            _formatTime(_heureDebut),
            _formatTime(_heureFin),
            _selectedModule!.idModule,
            _selectedFiliere!.idFiliere,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filieres = context.watch<FiliereProvider>().filieres;
    final modules = context.watch<ModuleProvider>().modules;

    return Scaffold(
      appBar:
          AppBar(title: const Text('Nouvelle s\u00e9ance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Date picker ──────────────────────────────────────────────────
          _SectionLabel(label: 'Date de la s\u00e9ance'),
          const SizedBox(height: 8),
          _TappableCard(
            onTap: _pickDate,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        _formatDateDisplay(_date),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Time pickers ─────────────────────────────────────────────────
          _SectionLabel(label: 'Horaire'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TappableCard(
                  onTap: () => _pickTime(true),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.presentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.login_rounded,
                            color: AppColors.present, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('D\u00e9but',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          Text(
                            _heureDebut.format(context),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.present),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TappableCard(
                  onTap: () => _pickTime(false),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.absentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppColors.absent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fin',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          Text(
                            _heureFin.format(context),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.absent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Filiere dropdown ─────────────────────────────────────────────
          _SectionLabel(label: 'Fili\u00e8re'),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(),
            child: DropdownButtonFormField<Filiere>(
              value: _selectedFiliere,
              decoration: const InputDecoration(
                hintText: 'S\u00e9lectionner une fili\u00e8re',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: false,
                prefixIcon: Icon(Icons.school_outlined,
                    color: AppColors.textSecondary),
              ),
              items: filieres
                  .map((f) => DropdownMenuItem(
                      value: f, child: Text(f.nomFiliere)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFiliere = v),
            ),
          ),
          const SizedBox(height: 12),

          // ── Module dropdown ──────────────────────────────────────────────
          _SectionLabel(label: 'Module'),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration(),
            child: DropdownButtonFormField<Module>(
              value: _selectedModule,
              decoration: const InputDecoration(
                hintText: 'S\u00e9lectionner un module',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: false,
                prefixIcon: Icon(Icons.menu_book_outlined,
                    color: AppColors.textSecondary),
              ),
              items: modules
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(m.nomModule)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedModule = v),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.absentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.absent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.absent, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Cr\u00e9er la s\u00e9ance'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}

class _TappableCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _TappableCard({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }
}
