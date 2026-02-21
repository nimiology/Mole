import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mole_provider.dart';
import '../widgets/sidebar_nav.dart';
import 'clean_screen.dart';
import 'uninstall_screen.dart';
import 'optimize_screen.dart';
import 'analyze_screen.dart';
import 'status_screen.dart';
import 'purge_screen.dart';
import 'installer_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final _screens = [
    const CleanScreen(),
    const UninstallScreen(),
    const OptimizeScreen(),
    const AnalyzeScreen(),
    const StatusScreen(),
    const PurgeScreen(),
    const InstallerScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);

    return Scaffold(
      body: Row(
        children: [
          const SidebarNav(),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}
