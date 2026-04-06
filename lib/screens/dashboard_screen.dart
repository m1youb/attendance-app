import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      final stats = await ApiService.getStats(token);
      setState(() => _stats = stats);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('R\u00e9essayer'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ],
          ),
        ),
      );
    }

    final byFiliere =
        (_stats!['by_filiere'] as List).cast<Map<String, dynamic>>();
    final topAbsentees =
        (_stats!['top_absentees'] as List).cast<Map<String, dynamic>>();

    // Compute totals for the summary cards
    int totalPresent = 0, totalAbsent = 0, totalRetard = 0;
    for (final f in byFiliere) {
      totalPresent += (f['present_count'] as int);
      final total = f['total_records'] as int;
      totalAbsent += (total - (f['present_count'] as int));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Summary stat cards ──────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Pr\u00e9sents',
                value: totalPresent,
                color: AppColors.present,
                lightColor: AppColors.presentLight,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Absents',
                value: totalAbsent,
                color: AppColors.absent,
                lightColor: AppColors.absentLight,
                icon: Icons.cancel_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Fili\u00e8res',
                value: byFiliere.length,
                color: AppColors.primary,
                lightColor: AppColors.primaryLight,
                icon: Icons.school_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Attendance by filiere ───────────────────────────────────────
          _SectionHeader(title: 'Pr\u00e9sence par fili\u00e8re'),
          const SizedBox(height: 10),
          if (byFiliere.isEmpty)
            _EmptyState(
                icon: Icons.bar_chart_rounded,
                message: 'Aucune donn\u00e9e disponible')
          else
            ...byFiliere.map((f) {
              final total = f['total_records'] as int;
              final present = f['present_count'] as int;
              final pct = total == 0 ? 0.0 : present / total;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f['nom_filiere'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pct >= 0.75
                                ? AppColors.presentLight
                                : pct >= 0.5
                                    ? AppColors.retardLight
                                    : AppColors.absentLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(pct * 100).round()}\u0025',
                            style: TextStyle(
                              color: pct >= 0.75
                                  ? AppColors.present
                                  : pct >= 0.5
                                      ? AppColors.retard
                                      : AppColors.absent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pct >= 0.75
                              ? AppColors.present
                              : pct >= 0.5
                                  ? AppColors.retard
                                  : AppColors.absent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$present / $total pr\u00e9sents',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),

          // ── Top absentees ───────────────────────────────────────────────
          _SectionHeader(title: 'Top absences'),
          const SizedBox(height: 10),
          if (topAbsentees.isEmpty)
            _EmptyState(
                icon: Icons.celebration_rounded,
                message: 'Aucune absence enregistr\u00e9e')
          else
            Container(
              decoration: cardDecoration(),
              child: Column(
                children: topAbsentees.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.absentLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: AppColors.absent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a['prenom']} ${a['nom']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.absentLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${a['absence_count']} abs.',
                                style: const TextStyle(
                                  color: AppColors.absent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < topAbsentees.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color lightColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.lightColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.divider),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
