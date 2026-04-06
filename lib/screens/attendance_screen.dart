import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seance.dart';
import '../models/etudiant.dart';
import '../providers/auth_provider.dart';
import '../providers/etudiant_provider.dart';
import '../providers/module_provider.dart';
import '../providers/filiere_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const _allStatuts = ['Present', 'Absent', 'Retard', 'Justifie'];

String _labelFor(String s) {
  switch (s) {
    case 'Present':
      return 'Pr\u00e9sent';
    case 'Absent':
      return 'Absent';
    case 'Retard':
      return 'Retard';
    case 'Justifie':
      return 'Justifi\u00e9';
    default:
      return s;
  }
}

class AttendanceScreen extends StatefulWidget {
  final Seance seance;
  const AttendanceScreen({super.key, required this.seance});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = true;
  bool _submitting = false;
  List<Etudiant> _students = [];
  final Map<int, String> _statuts = {};
  final Map<int, TextEditingController> _commentCtrls = {};
  final Set<int> _expanded = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _commentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      final etudiantProvider = context.read<EtudiantProvider>();
      if (etudiantProvider.etudiants.isEmpty) {
        await etudiantProvider.load(token);
      }
      _students = etudiantProvider.byFiliere(widget.seance.idFiliere);
      for (final s in _students) {
        _statuts[s.idEtudiant] = 'Absent';
        _commentCtrls[s.idEtudiant] = TextEditingController();
      }
      final presences =
          await ApiService.getPresences(token, widget.seance.idSeance);
      for (final p in presences) {
        _statuts[p.idEtudiant] = p.statut;
        _commentCtrls[p.idEtudiant]?.text = p.commentaire;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final records = _students
          .map((s) => {
                'id_etudiant': s.idEtudiant,
                'statut': _statuts[s.idEtudiant] ?? 'Absent',
                'commentaire': _commentCtrls[s.idEtudiant]?.text ?? '',
              })
          .toList();
      await ApiService.submitPresences(token, widget.seance.idSeance, records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Pr\u00e9sences enregistr\u00e9es'),
              ],
            ),
            backgroundColor: AppColors.present,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.absent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  // Quick-set all students to a status
  void _setAll(String statut) {
    setState(() {
      for (final id in _statuts.keys) {
        _statuts[id] = statut;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moduleProvider = context.watch<ModuleProvider>();
    final filiereProvider = context.watch<FiliereProvider>();
    final moduleName = moduleProvider.nomById(widget.seance.idModule);
    final filiereName = filiereProvider.nomById(widget.seance.idFiliere);
    final timeRange =
        '${widget.seance.heureDebut.substring(0, 5)} \u2013 ${widget.seance.heureFin.substring(0, 5)}';

    // Count present for subtitle
    final presentCount =
        _statuts.values.where((s) => s == 'Present').length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(moduleName,
                style: const TextStyle(fontSize: 17, color: Colors.white)),
            Text(
              '$filiereName  \u2022  $timeRange',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('R\u00e9essayer'),
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44)),
                        ),
                      ],
                    ),
                  ),
                )
              : _students.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun \u00e9tudiant dans cette fili\u00e8re.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : Column(
                      children: [
                        // ── Summary bar ─────────────────────────────────
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$presentCount / ${_students.length} pr\u00e9sents',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              // Quick-set buttons
                              _QuickSetBtn(
                                  label: 'Tous pr\u00e9sents',
                                  color: AppColors.present,
                                  onTap: () => _setAll('Present')),
                              const SizedBox(width: 6),
                              _QuickSetBtn(
                                  label: 'Tous absents',
                                  color: AppColors.absent,
                                  onTap: () => _setAll('Absent')),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // ── Student list ─────────────────────────────────
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                16, 12, 16, 100),
                            itemCount: _students.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _buildStudentCard(_students[i]),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: _loading || _students.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _submitting ? null : _submit,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Enregistrer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildStudentCard(Etudiant student) {
    final id = student.idEtudiant;
    final current = _statuts[id] ?? 'Absent';
    final isExpanded = _expanded.contains(id);

    return Container(
      decoration: cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with initial
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusLightColor(current),
                  child: Text(
                    student.prenom.isNotEmpty
                        ? student.prenom[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: statusColor(current),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student.prenom} ${student.nom}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        _labelFor(current),
                        style: TextStyle(
                            color: statusColor(current),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: isExpanded
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => isExpanded
                      ? _expanded.remove(id)
                      : _expanded.add(id)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status pill buttons
            Row(
              children: _allStatuts
                  .map((s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _statuts[id] = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: current == s
                                    ? statusColor(s)
                                    : statusLightColor(s),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _labelFor(s),
                                  style: TextStyle(
                                    color: current == s
                                        ? Colors.white
                                        : statusColor(s),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _commentCtrls[id],
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                ),
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickSetBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickSetBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
