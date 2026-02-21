import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class CleanScreen extends ConsumerStatefulWidget {
  const CleanScreen({super.key});

  @override
  ConsumerState<CleanScreen> createState() => _CleanScreenState();
}

class _CleanScreenState extends ConsumerState<CleanScreen> {
  bool _isScanning = false;
  bool _isCleaning = false;
  String _output = '';
  String _totalSize = '—';

  final List<_Category> _categories = [
    _Category('User Cache', Icons.folder_zip, Color(0xFF3B82F6), 'Active', '—'),
    _Category('Browser', Icons.public, Color(0xFFF97316), '12 sites', '—'),
    _Category(
      'Dev Tools',
      Icons.terminal,
      Color(0xFFA855F7),
      'Node/Docker',
      '—',
    ),
    _Category('Logs', Icons.description, Color(0xFFEAB308), '1.4k lines', '—'),
    _Category('App Cache', Icons.layers, Color(0xFF22D3EE), 'System apps', '—'),
    _Category('Trash', Icons.delete, Color(0xFFEF4444), 'Empty', '0 KB'),
  ];

  Future<void> _scan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _output = '';
      _totalSize = '—';
      for (var c in _categories) {
        c.size = '—';
        c.tag = 'Scanning...';
      }
    });
    try {
      final service = ref.read(moleServiceProvider);
      final stream = service.cleanDryRunStream();
      await for (final line in stream) {
        if (!mounted) return;
        setState(() {
          _output += '$line\n';
          _parseCategories(line);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _output += '\nError: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          // Sub-feature: Any category that was empty and never got parsed
          // should switch from "Scanning..." to "Clean" and "0 KB".
          for (var c in _categories) {
            if (c.tag == 'Scanning...') {
              c.size = '0 KB';
              c.tag = 'Clean';
            }
          }
        });
      }
    }
  }

  Future<void> _clean() async {
    if (_isCleaning) return;
    setState(() {
      _isCleaning = true;
      _output = '';
      for (var c in _categories) {
        c.tag = 'Cleaning...';
      }
    });
    try {
      final service = ref.read(moleServiceProvider);
      final stream = service.cleanStream();
      await for (final line in stream) {
        if (!mounted) return;
        setState(() => _output += '$line\n');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _output += '\nError: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCleaning = false;
          _totalSize = '0 KB';
          for (var c in _categories) {
            c.size = '0 KB';
            c.tag = 'Clean';
          }
        });
      }
    }
  }

  void _parseCategories(String output) {
    final lines = output.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();

      // Match size at the end of lines like "... 2.87GB dry"
      final sizeMatch = RegExp(
        r'([\d.]+)\s*([KMGT]?B)',
        caseSensitive: false,
      ).firstMatch(line);
      final sizeStr = sizeMatch != null
          ? '${sizeMatch.group(1)} ${sizeMatch.group(2)}'
          : null;

      if (lower.contains('potential space:')) {
        final totalMatch = RegExp(
          r'potential space:\s*([\d.]+\s*[KMGT]?B)',
          caseSensitive: false,
        ).firstMatch(line);
        if (totalMatch != null)
          setState(() => _totalSize = totalMatch.group(1)!);
      } else if (lower.contains('cleaned') && lower.contains('items')) {
        final totalMatch = RegExp(
          r'cleaned.*?([\d.]+\s*[KMGT]?B)',
          caseSensitive: false,
        ).firstMatch(line);
        if (totalMatch != null)
          setState(() => _totalSize = totalMatch.group(1)!);
      }

      if (sizeStr != null) {
        if (lower.contains('user app cache')) {
          _updateCategory(0, sizeStr, line);
        } else if (lower.contains('browser')) {
          _updateCategory(1, sizeStr, line);
        } else if (lower.contains('xcode') ||
            lower.contains('android') ||
            lower.contains('docker')) {
          _updateCategory(2, sizeStr, line);
        } else if (lower.contains('log')) {
          _updateCategory(3, sizeStr, line);
        } else if (lower.contains('system cache') ||
            lower.contains('application support')) {
          _updateCategory(4, sizeStr, line);
        } else if (lower.contains('trash')) {
          _updateCategory(5, sizeStr, line);
        }
      }
    }
  }

  void _updateCategory(int index, String size, String rawLine) {
    // Extract item count if present (e.g. "76 items,")
    final itemsMatch = RegExp(r'(\d+)\s*items?').firstMatch(rawLine);
    final tag = itemsMatch != null ? '${itemsMatch.group(1)} items' : 'Active';

    setState(() {
      _categories[index].size = size;
      _categories[index].tag = tag;
    });
  }

  Future<void> _showReviewDetails() async {
    final file = File(
      '${Platform.environment['HOME']}/.config/mole/clean-list.txt',
    );
    if (!await file.exists()) return;

    final lines = await file.readAsLines();
    final categories = <String, List<String>>{};
    String currentCategory = 'Other';

    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      if (line.startsWith('===') && line.endsWith('===')) {
        currentCategory = line.replaceAll('===', '').trim();
        categories[currentCategory] = [];
      } else {
        categories[currentCategory]?.add(line);
      }
    }

    // Remove empty categories
    categories.removeWhere((_, items) => items.isEmpty);

    if (!mounted) return;

    // Track deselected paths
    final Set<String> deselectedPaths = {};

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, _, __) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 650,
                  height: 600,
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Modal Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0x1AFFFFFF)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Review Selected Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSlate400,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      // Modal Content
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final catName = categories.keys.elementAt(index);
                            final items = categories[catName]!;

                            // Check if category is partially or fully selected
                            final allPaths = items
                                .map((i) => i.split(' # ')[0].trim())
                                .toList();
                            final deselectedCount = allPaths
                                .where((p) => deselectedPaths.contains(p))
                                .length;
                            final isAllSelected = deselectedCount == 0;
                            final isPartiallySelected =
                                deselectedCount > 0 &&
                                deselectedCount < allPaths.length;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.85,
                                      child: Checkbox(
                                        value: isPartiallySelected
                                            ? null
                                            : isAllSelected,
                                        tristate: true,
                                        activeColor: AppColors.primary,
                                        checkColor: AppColors.background,
                                        side: const BorderSide(
                                          color: AppColors.textSlate500,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setModalState(() {
                                            if (val == true || val == null) {
                                              // Select all
                                              deselectedPaths.removeAll(
                                                allPaths,
                                              );
                                            } else {
                                              // Deselect all
                                              deselectedPaths.addAll(allPaths);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      catName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 24,
                                    left: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x08FFFFFF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0x08FFFFFF),
                                    ),
                                  ),
                                  child: Column(
                                    children: items.map((item) {
                                      final parts = item.split(' # ');
                                      final path = parts[0].trim();
                                      final size = parts.length > 1
                                          ? parts[1].trim()
                                          : '';
                                      final isSelected = !deselectedPaths
                                          .contains(path);

                                      return InkWell(
                                        onTap: () {
                                          setModalState(() {
                                            if (isSelected) {
                                              deselectedPaths.add(path);
                                            } else {
                                              deselectedPaths.remove(path);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Transform.scale(
                                                scale: 0.8,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  activeColor:
                                                      AppColors.primary,
                                                  checkColor:
                                                      AppColors.background,
                                                  side: const BorderSide(
                                                    color:
                                                        AppColors.textSlate500,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  onChanged: (val) {
                                                    setModalState(() {
                                                      if (val == true) {
                                                        deselectedPaths.remove(
                                                          path,
                                                        );
                                                      } else {
                                                        deselectedPaths.add(
                                                          path,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.folder,
                                                size: 16,
                                                color: AppColors.textSlate500,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  path,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                              .textSlate500,
                                                    decoration: isSelected
                                                        ? null
                                                        : TextDecoration
                                                              .lineThrough,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                size,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors.textSlate400
                                                      : AppColors.textSlate500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Modal Footer
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0x1AFFFFFF)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                foregroundColor: AppColors.textPrimary,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                // Add deselected items to whitelist
                                if (deselectedPaths.isNotEmpty) {
                                  final wlFile = File(
                                    '${Platform.environment['HOME']}/.config/mole/whitelist',
                                  );
                                  if (await wlFile.exists()) {
                                    await wlFile.writeAsString(
                                      '\n' + deselectedPaths.join('\n'),
                                      mode: FileMode.append,
                                    );
                                  } else {
                                    await wlFile.create(recursive: true);
                                    await wlFile.writeAsString(
                                      deselectedPaths.join('\n'),
                                    );
                                  }
                                }
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isScanning || _isCleaning;

    return Column(
      children: [
        // Main scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            children: [
              // Header
              Text('Clean', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              const Text(
                'Scan and remove system junk',
                style: TextStyle(fontSize: 18, color: AppColors.textSlate400),
              ),
              const SizedBox(height: 32),

              // Category grid — 3 columns × 2 rows
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, i) =>
                    _CategoryCard(category: _categories[i]),
              ),

              // Live output log
              if (_output.isNotEmpty) ...[
                const SizedBox(height: 40),
                _TerminalLog(output: _output),
              ],
            ],
          ),
        ),

        // Bottom action bar
        _BottomBar(
          totalSize: _totalSize,
          isBusy: isBusy,
          onScan: _isScanning ? null : _scan,
          onClean: _isCleaning ? null : _clean,
          onReview: _totalSize != '—' && !isBusy ? _showReviewDetails : null,
        ),
      ],
    );
  }
}

// ─── Models ─────────────────────────────────────────────────

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  String tag;
  String size;
  _Category(this.name, this.icon, this.color, this.tag, this.size);
}

// ─── Category Card ──────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final _Category category;
  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.3)
                : const Color(0x0DFFFFFF),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(c.icon, color: c.color, size: 20),
                ),
                Text(
                  c.tag,
                  style: TextStyle(fontSize: 13, color: AppColors.textSlate500),
                ),
              ],
            ),
            const Spacer(),
            Text(
              c.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              c.size,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: c.size == '0 KB'
                    ? AppColors.textSlate500
                    : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Terminal Log ───────────────────────────────────────────

class _TerminalLog extends StatelessWidget {
  final String output;
  const _TerminalLog({required this.output});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0x0DFFFFFF),
              border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIVE OUTPUT LOG',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                    color: AppColors.textSlate400,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Output
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: output
                  .split('\n')
                  .where((l) => l.trim().isNotEmpty)
                  .length,
              itemBuilder: (context, index) {
                final line = output
                    .split('\n')
                    .where((l) => l.trim().isNotEmpty)
                    .toList()[index];

                // Strip ANSI escape sequences
                final cleanLine = line.replaceAll(
                  RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'),
                  '',
                );

                Color color = AppColors.textSlate400;
                IconData? icon;
                Color iconColor = color;
                bool isBold = false;

                if (cleanLine.startsWith('➤')) {
                  color = AppColors.textPrimary;
                  isBold = true;
                  icon = Icons.folder_open;
                  iconColor = AppColors.accentBlue;
                } else if (cleanLine.startsWith('✓')) {
                  color = AppColors.primary.withValues(alpha: 0.8);
                  icon = Icons.check_circle_outline;
                  iconColor = AppColors.primary;
                } else if (cleanLine.startsWith('→') ||
                    cleanLine.startsWith('⇾')) {
                  color = AppColors.textSlate400;
                  icon = Icons.subdirectory_arrow_right;
                  iconColor = AppColors.textSlate500;
                } else if (cleanLine.startsWith('⚙')) {
                  color = AppColors.accentPurple.withValues(alpha: 0.9);
                  icon = Icons.settings;
                  iconColor = AppColors.accentPurple;
                } else if (cleanLine.contains('Error:')) {
                  color = AppColors.accentRed;
                  icon = Icons.error_outline;
                  iconColor = AppColors.accentRed;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: iconColor),
                        const SizedBox(width: 8),
                      ] else ...[
                        const SizedBox(width: 22),
                      ],
                      Expanded(
                        child: Text(
                          cleanLine.replaceAll(RegExp(r'^[➤✓→⇾⚙]\s*'), ''),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: isBold
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: color,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Action Bar ──────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final String totalSize;
  final bool isBusy;
  final VoidCallback? onScan;
  final VoidCallback? onClean;
  final VoidCallback? onReview;

  const _BottomBar({
    required this.totalSize,
    required this.isBusy,
    this.onScan,
    this.onClean,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.sidebar.withValues(alpha: 0.5),
        border: const Border(top: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL TO CLEAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalSize,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0x1AFFFFFF),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EFFICIENCY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '+12%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Buttons
          if (onReview != null) ...[
            _ActionButton(
              label: 'Review Details',
              icon: Icons.checklist,
              isOutlined: true,
              isLoading: false,
              onPressed: onReview,
            ),
            const SizedBox(width: 16),
          ],
          _ActionButton(
            label: 'Scan Again',
            isOutlined: true,
            isLoading: isBusy,
            onPressed: onScan,
          ),
          const SizedBox(width: 16),
          _ActionButton(
            label: 'Clean Now',
            icon: Icons.bolt,
            isOutlined: false,
            isLoading: isBusy,
            onPressed: onClean,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    this.icon,
    required this.isOutlined,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : (_hovered
                      ? AppColors.primary.withValues(alpha: 1.0)
                      : AppColors.primary),
            borderRadius: BorderRadius.circular(8),
            border: widget.isOutlined
                ? Border.all(color: const Color(0x1AFFFFFF))
                : null,
            boxShadow: !widget.isOutlined
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      widget.isOutlined
                          ? AppColors.textPrimary
                          : AppColors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isOutlined
                      ? AppColors.textPrimary
                      : AppColors.background,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.isOutlined
                      ? AppColors.textPrimary
                      : AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
