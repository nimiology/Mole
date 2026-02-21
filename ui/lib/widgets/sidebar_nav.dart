import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class SidebarNav extends ConsumerWidget {
  const SidebarNav({super.key});

  static const _navItems = [
    _NavItem(Icons.cleaning_services, 'Clean', AppColors.primary),
    _NavItem(Icons.delete_sweep, 'Uninstall', AppColors.accentRed),
    _NavItem(Icons.speed, 'Optimize', AppColors.accentOrange),
    _NavItem(Icons.analytics_outlined, 'Analyze', AppColors.accentBlue),
    _NavItem(Icons.monitor_heart, 'Status', AppColors.accentPurple),
    _NavItem(Icons.content_cut, 'Purge', AppColors.primary),
    _NavItem(Icons.inventory_2, 'Installers', AppColors.accentPurple),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final version = ref.watch(moleVersionProvider);

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mole',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SYSTEM PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _NavTile(
                      item: item,
                      isSelected: isSelected,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state =
                              index,
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom disk usage card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disk Usage',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSlate400,
                        ),
                      ),
                      Text(
                        '82%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.82,
                      minHeight: 6,
                      backgroundColor: const Color(0x1AFFFFFF),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  if (version.value != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'v${version.value}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color accentColor;
  const _NavItem(this.icon, this.label, this.accentColor);
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.accentColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? color.withValues(alpha: 0.1)
                : _hovered
                ? const Color(0x0DFFFFFF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: widget.isSelected
                    ? color
                    : (_hovered
                          ? AppColors.textPrimary
                          : AppColors.textSlate400),
              ),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.isSelected
                      ? color
                      : (_hovered
                            ? AppColors.textPrimary
                            : AppColors.textSlate400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
