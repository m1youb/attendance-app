import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/filiere_provider.dart';
import '../providers/module_provider.dart';
import '../providers/etudiant_provider.dart';
import '../providers/seance_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'seances_screen.dart';
import 'students_screen.dart';
import 'modules_screen.dart';
import 'filieres_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    SeancesScreen(),
    StudentsScreen(),
    ModulesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final token = context.read<AuthProvider>().token!;
    await Future.wait([
      context.read<FiliereProvider>().load(token),
      context.read<ModuleProvider>().load(token),
      context.read<EtudiantProvider>().load(token),
      context.read<SeanceProvider>().load(token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prof = auth.professeur;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _index == 0
                  ? 'Bonjour, Pr ${prof?.nom ?? ''}'
                  : _index == 1
                      ? 'Mes S\u00e9ances'
                      : _index == 2
                          ? '\u00c9tudiants'
                          : 'Modules',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            if (_index == 0 && prof != null)
              Text(
                prof.email,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Fili\u00e8res',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FilieresScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                prof != null ? prof.prenom[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prof != null ? '${prof.prenom} ${prof.nom}' : '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      prof?.email ?? '',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 18, color: AppColors.absent),
                    SizedBox(width: 10),
                    Text('D\u00e9connexion',
                        style: TextStyle(color: AppColors.absent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'S\u00e9ances',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: '\u00c9tudiants',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Modules',
          ),
        ],
      ),
    );
  }
}
