import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../providers/module_provider.dart';
import '../providers/filiere_provider.dart';
import '../models/seance.dart';
import '../theme/app_theme.dart';
import 'create_seance_screen.dart';
import 'attendance_screen.dart';

class SeancesScreen extends StatefulWidget {
  const SeancesScreen({super.key});

  @override
  State<SeancesScreen> createState() => _SeancesScreenState();
}

class _SeancesScreenState extends State<SeancesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<SeanceProvider>().load(token);
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final parsed = DateTime(d.year, d.month, d.day);
      if (parsed == today) return "Aujourd'hui";
      if (parsed == today.subtract(const Duration(days: 1))) return 'Hier';
      return DateFormat('EEEE d MMMM', 'fr').format(d);
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final seanceProvider = context.watch<SeanceProvider>();
    final moduleProvider = context.watch<ModuleProvider>();
    final filiereProvider = context.watch<FiliereProvider>();

    final seances = seanceProvider.mySeances(auth.profId!);

    final Map<String, List<Seance>> grouped = {};
    for (final s in seances) {
      grouped.putIfAbsent(s.dateSeance, () => []).add(s);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: seanceProvider.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : seances.isEmpty
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
                        child: const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune s\u00e9ance',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cr\u00e9ez votre premi\u00e8re s\u00e9ance',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: dates.length,
                    itemBuilder: (context, i) {
                      final date = dates[i];
                      final list = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(
                              _formatDate(date),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...list.map((s) => _SeanceCard(
                                seance: s,
                                moduleName:
                                    moduleProvider.nomById(s.idModule),
                                filiereName:
                                    filiereProvider.nomById(s.idFiliere),
                                timeStart: _formatTime(s.heureDebut),
                                timeEnd: _formatTime(s.heureFin),
                              )),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSeanceScreen()),
          );
          _load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle s\u00e9ance',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SeanceCard extends StatelessWidget {
  final Seance seance;
  final String moduleName;
  final String filiereName;
  final String timeStart;
  final String timeEnd;

  const _SeanceCard({
    required this.seance,
    required this.moduleName,
    required this.filiereName,
    required this.timeStart,
    required this.timeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AttendanceScreen(seance: seance)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time column
                Column(
                  children: [
                    Text(timeStart,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary)),
                    Container(
                      width: 1,
                      height: 18,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.divider,
                    ),
                    Text(timeEnd,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(width: 16),
                // Vertical divider
                Container(
                  width: 3,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moduleName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filiereName,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
