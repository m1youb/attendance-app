import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF1240A8);
  static const primaryLight = Color(0xFFEBF2FF);
  static const background = Color(0xFFF4F7FF);
  static const surface = Colors.white;
  static const present = Color(0xFF16A34A);
  static const presentLight = Color(0xFFDCFCE7);
  static const absent = Color(0xFFDC2626);
  static const absentLight = Color(0xFFFFE4E4);
  static const retard = Color(0xFFEA580C);
  static const retardLight = Color(0xFFFFEDD5);
  static const justifie = Color(0xFF7C3AED);
  static const justifieLight = Color(0xFFEDE9FE);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12);
            }
            return const TextStyle(
                color: AppColors.textSecondary, fontSize: 12);
          }),
          elevation: 8,
          shadowColor: Colors.black12,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          space: 1,
        ),
      );
}

// Reusable shadow decoration for cards
BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    );

Color statusColor(String statut) {
  switch (statut) {
    case 'Present':
      return AppColors.present;
    case 'Absent':
      return AppColors.absent;
    case 'Retard':
      return AppColors.retard;
    case 'Justifie':
      return AppColors.justifie;
    default:
      return AppColors.textSecondary;
  }
}

Color statusLightColor(String statut) {
  switch (statut) {
    case 'Present':
      return AppColors.presentLight;
    case 'Absent':
      return AppColors.absentLight;
    case 'Retard':
      return AppColors.retardLight;
    case 'Justifie':
      return AppColors.justifieLight;
    default:
      return AppColors.divider;
  }
}
