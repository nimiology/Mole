import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class InstallerScreen extends ConsumerStatefulWidget {
  const InstallerScreen({super.key});

  @override
  ConsumerState<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends ConsumerState<InstallerScreen> {
  bool _isLoading = false;
  String _output = '';

  // Dummy detected files (populated after scan)
  final List<_InstallerFile> _files = [];

  Future<void> _findInstallers() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });
    try {
      final service = ref.read(moleServiceProvider);
      final result = await service.installer();
      setState(() {
        _output = result;
        _parseFiles(result);
      });
    } catch (e) {
      setState(() => _output = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseFiles(String output) {
    final lines = output.split('\n');
    final files = <_InstallerFile>[];
    for (final line in lines) {
      final match = RegExp(
        r'(.+\.(?:dmg|pkg|zip))\s*[–-]\s*([\d.]+\s*\w+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim().split('/').last;
        final size = match.group(2)!.trim();
        final ext = name.split('.').last.toUpperCase();
        files.add(
          _InstallerFile(
            name: name,
            path: line.trim(),
            type: ext,
            size: size,
            selected: true,
          ),
        );
      }
    }
    setState(
      () => _files
        ..clear()
        ..addAll(files),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Installers',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find and remove disk images and packages taking up space.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
                _FindButton(
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _findInstallers,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Source cards
            Row(
              children: [
                Expanded(
                  child: _SourceCard(
                    icon: Icons.download,
                    color: AppColors.primary,
                    title: 'Downloads',
                    description: 'Detects setup files in your primary folder.',
                    status: 'READY TO SCAN',
                    statusColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceCard(
                    icon: Icons.desktop_mac,
                    color: AppColors.accentBlue,
                    title: 'Desktop',
                    description:
                        'Locates installation clutter on your workspace.',
                    status: 'CLEAN UP NEEDED',
                    statusColor: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceCard(
                    icon: Icons.terminal,
                    color: AppColors.accentOrange,
                    title: 'Homebrew Cache',
                    description:
                        'Clears cached formula installers and old versions.',
                    status: '2.4 GB CACHED',
                    statusColor: AppColors.accentOrange,
                  ),
                ),
              ],
            ),

            // Detected files table
            if (_files.isNotEmpty || _output.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DETECTED FILES (${_files.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Selected: — GB',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_files.isNotEmpty)
                _FileTable(
                  files: _files,
                  onToggle: (i) {
                    setState(
                      () => _files[i] = _files[i].copyWith(
                        selected: !_files[i].selected,
                      ),
                    );
                  },
                )
              else
                // Show raw output
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: SelectableText(
                    _output,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Menlo',
                      color: AppColors.textSlate400,
                      height: 1.6,
                    ),
                  ),
                ),
            ],
          ],
        ),

        // Floating clean bar
        if (_files.isNotEmpty)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(child: _FloatingCleanBar(files: _files)),
          ),
      ],
    );
  }
}

// ─── Models ──────────────────────────────

class _InstallerFile {
  final String name;
  final String path;
  final String type;
  final String size;
  final bool selected;
  const _InstallerFile({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.selected,
  });
  _InstallerFile copyWith({bool? selected}) => _InstallerFile(
    name: name,
    path: path,
    type: type,
    size: size,
    selected: selected ?? this.selected,
  );
}

// ─── Source Card ─────────────────────────

class _SourceCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String status;
  final Color statusColor;

  const _SourceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
  });

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
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
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              transformAlignment: Alignment.center,
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSlate500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: widget.statusColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── File Table ──────────────────────────

class _FileTable extends StatelessWidget {
  final List<_InstallerFile> files;
  final void Function(int) onToggle;
  const _FileTable({required this.files, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.borderDark.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.borderDark),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 48),
                SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Text(
                    'FILE NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'SIZE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(width: 24),
              ],
            ),
          ),
          // Rows
          ...List.generate(files.length, (i) {
            final f = files[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: i < files.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderDark),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => onToggle(i),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: f.selected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: f.selected
                                  ? AppColors.primary
                                  : AppColors.borderDark,
                              width: 1.5,
                            ),
                          ),
                          child: f.selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.borderDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getFileIcon(f.type),
                            color: AppColors.textSlate500,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                f.path.contains('/')
                                    ? '~/${f.path.split('/').reversed.skip(1).first}'
                                    : '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 80, child: _TypeBadge(type: f.type)),
                  SizedBox(
                    width: 80,
                    child: Text(
                      f.size,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'DMG':
        return Icons.album;
      case 'PKG':
        return Icons.inventory_2;
      case 'ZIP':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  Color get _color {
    switch (type) {
      case 'DMG':
        return AppColors.accentPurple;
      case 'PKG':
        return AppColors.accentBlue;
      case 'ZIP':
        return AppColors.accentOrange;
      default:
        return AppColors.textSlate500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

// ─── Floating Clean Bar ──────────────────

class _FloatingCleanBar extends StatelessWidget {
  final List<_InstallerFile> files;
  const _FloatingCleanBar({required this.files});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL SAVINGS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSlate400,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '4.44 GB',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0x1AFFFFFF),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_delete, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Clean Selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Find Button ─────────────────────────

class _FindButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _FindButton({required this.isLoading, this.onPressed});

  @override
  State<_FindButton> createState() => _FindButtonState();
}

class _FindButtonState extends State<_FindButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.9)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.search, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.isLoading ? 'Scanning...' : 'Find Installers',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
