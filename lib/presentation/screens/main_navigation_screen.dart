import 'package:flutter/material.dart';
import 'package:planner/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:planner/features/exams/presentation/screens/exams_list_screen.dart';
import 'package:planner/features/rooms/presentation/screens/rooms_screen.dart';
import 'package:planner/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:planner/features/profile/presentation/screens/profile_screen.dart';
import 'package:planner/core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/presentation/providers/navigation_provider.dart';
import 'package:planner/features/profile/presentation/providers/language_provider.dart';
import 'package:planner/core/localization/app_localizations.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = ref.watch(languageProvider);

    final List<Widget> screens = [
      const DashboardScreen(),
      const ExamsListScreen(),
      const RoomsScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];

    void onItemTapped(int index) {
      ref.read(navigationProvider.notifier).state = index;
    }

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? Colors.white54 : Colors.black38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              activeIcon: const Icon(Icons.dashboard_rounded),
              label: AppLocalizations.get('home', langCode),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_rounded),
              activeIcon: const Icon(Icons.assignment_rounded),
              label: AppLocalizations.get('exams', langCode),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.meeting_room_rounded),
              activeIcon: const Icon(Icons.meeting_room_rounded),
              label: AppLocalizations.get('rooms', langCode),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today_rounded),
              activeIcon: const Icon(Icons.calendar_today_rounded),
              label: AppLocalizations.get('calendar', langCode),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: AppLocalizations.get('profile', langCode),
            ),
          ],
        ),
      ),
    );
  }
}
