import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class UninstallScreen extends ConsumerStatefulWidget {
  const UninstallScreen({super.key});

  @override
  ConsumerState<UninstallScreen> createState() => _UninstallScreenState();
}

class _UninstallScreenState extends ConsumerState<UninstallScreen> {
  bool _isLoading = false;
  bool _hasScanned = false;
  String _searchQuery = '';
  final List<_AppItem> _apps = [];

  @override
  void initState() {
    super.initState();
    // Do not auto-load apps, wait for explicit scan
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    // Add artificial delay for visual scanning effect
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final apps = <_AppItem>[];

      // Run du on all .app folders in /Applications for accurate bundle sizes
      final result = await Process.run('sh', [
        '-c',
        'du -sk /Applications/*.app',
      ]);
      if (result.exitCode == 0 || result.exitCode == 1) {
        // 1 means some permissions denied, but it still prints what it can
        final lines = (result.stdout as String).split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line.trim());
          if (match != null) {
            final kb = int.tryParse(match.group(1)!) ?? 0;
            final path = match.group(2)!;
            final name = path.split('/').last.replaceAll('.app', '');

            String sizeStr = '—';
            final bytes = kb * 1024;
            if (bytes > 1024 * 1024 * 1024) {
              sizeStr =
                  '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
            } else if (bytes > 1024 * 1024) {
              sizeStr = '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
            } else {
              sizeStr = '${(kb / 1024).toStringAsFixed(1)} MB';
            }

            apps.add(
              _AppItem(name: name, path: path, size: sizeStr, selected: false),
            );
          }
        }
      }

      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(
        () => _apps
          ..clear()
          ..addAll(apps),
      );
    } catch (_) {}
    setState(() {
      _isLoading = false;
      _hasScanned = true;
    });
  }

  List<_AppItem> get _filteredApps {
    if (_searchQuery.isEmpty) return _apps;
    return _apps
        .where((a) => a.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int get _selectedCount => _apps.where((a) => a.selected).length;

  Future<void> _uninstall() async {
    final selected = _apps.where((a) => a.selected).toList();
    if (selected.isEmpty) return;
    try {
      // In a real app we'd map this to `mo uninstall` using paths
      // For now we just mock
      setState(() {
        _apps.removeWhere((a) => a.selected);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Uninstall',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Remove apps and all associated system files',
                  style: TextStyle(fontSize: 18, color: AppColors.textSlate400),
                ),

                // Search bar (only if scanned)
                if (_hasScanned) ...[
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.textSlate400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search apps by name...',
                              hintStyle: TextStyle(
                                color: AppColors.textSlate400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Main Content Area
                Expanded(
                  child: !_hasScanned
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.apps_outage,
                                  size: 32,
                                  color: AppColors.textSlate400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_isLoading) ...[
                                const CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Scanning Applications...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSlate400,
                                  ),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: _loadApps,
                                  icon: const Icon(Icons.search),
                                  label: const Text('Scan System'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              // Table header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0x0D000000),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            final allSelected = _apps.every(
                                              (a) => a.selected,
                                            );
                                            setState(() {
                                              for (
                                                int i = 0;
                                                i < _apps.length;
                                                i++
                                              ) {
                                                _apps[i] = _apps[i].copyWith(
                                                  selected: !allSelected,
                                                );
                                              }
                                            });
                                          },
                                          child: _Checkbox(
                                            checked:
                                                _apps.isNotEmpty &&
                                                _apps.every((a) => a.selected),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        'APPLICATION',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSlate500,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'VERSION',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSlate500,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 80,
                                      child: Text(
                                        'SIZE',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSlate500,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),
                              // Table body
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _filteredApps.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                    indent: 0,
                                  ),
                                  itemBuilder: (context, index) {
                                    final app = _filteredApps[index];
                                    final appIndex = _apps.indexOf(app);
                                    return _AppRow(
                                      app: app,
                                      onToggle: () {
                                        setState(() {
                                          _apps[appIndex] = app.copyWith(
                                            selected: !app.selected,
                                          );
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selection Summary',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSlate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_selectedCount apps selected',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _UninstallButton(
                count: _selectedCount,
                onPressed: _selectedCount > 0 ? _uninstall : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Models ─────────────────────────────

class _AppItem {
  final String name;
  final String path;
  final String size;
  final bool selected;
  const _AppItem({
    required this.name,
    required this.path,
    required this.size,
    required this.selected,
  });
  _AppItem copyWith({bool? selected}) => _AppItem(
    name: name,
    path: path,
    size: size,
    selected: selected ?? this.selected,
  );
}

// ─── Checkbox ───────────────────────────

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.accentRed : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.accentRed : AppColors.textTertiary,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

// ─── App Row ────────────────────────────

class _AppRow extends StatefulWidget {
  final _AppItem app;
  final VoidCallback onToggle;

  const _AppRow({required this.app, required this.onToggle});

  @override
  State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  bool _isHovered = false;
  File? _iconFile;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    try {
      final cacheDir = Directory(
        '${Platform.environment['TMPDIR'] ?? '/tmp'}mole_icons',
      );
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final pngPath = '${cacheDir.path}/${widget.app.path.hashCode}.png';
      final pngFile = File(pngPath);

      if (await pngFile.exists() && await pngFile.length() > 0) {
        if (mounted) setState(() => _iconFile = pngFile);
        return;
      }

      final plistFile = File('${widget.app.path}/Contents/Info.plist');
      if (!await plistFile.exists()) return;

      final plistContent = await plistFile.readAsString();
      final regex = RegExp(
        r'<key>CFBundleIconFile</key>\s*<string>(.*?)</string>',
        multiLine: true,
        dotAll: true,
      );
      final match = regex.firstMatch(plistContent);
      if (match == null) return;

      String icnsName = match.group(1)!.trim();
      if (!icnsName.endsWith('.icns')) icnsName += '.icns';

      final icnsFile = File('${widget.app.path}/Contents/Resources/$icnsName');
      if (!await icnsFile.exists()) return;

      final result = await Process.run('sips', [
        '-s',
        'format',
        'png',
        '--resampleWidth',
        '64',
        icnsFile.path,
        '--out',
        pngPath,
      ]);

      if (result.exitCode == 0 && await pngFile.exists() && mounted) {
        setState(() => _iconFile = pngFile);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: Container(
          color: _isHovered ? const Color(0x0AFFFFFF) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Center(child: _Checkbox(checked: widget.app.selected)),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _iconFile != null
                          ? Image.file(
                              _iconFile!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.apps,
                              size: 14,
                              color: AppColors.textSlate400,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.app.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  '—',
                  style: TextStyle(fontSize: 13, color: AppColors.textSlate400),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  widget.app.size,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Uninstall Button ───────────────────

class _UninstallButton extends StatefulWidget {
  final int count;
  final VoidCallback? onPressed;
  const _UninstallButton({required this.count, this.onPressed});

  @override
  State<_UninstallButton> createState() => _UninstallButtonState();
}

class _UninstallButtonState extends State<_UninstallButton> {
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
            color: widget.onPressed != null
                ? (_hovered ? const Color(0xFFDC2626) : AppColors.accentRed)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: AppColors.accentRed.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete,
                color: widget.onPressed != null
                    ? Colors.white
                    : AppColors.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Uninstall Apps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.onPressed != null
                      ? Colors.white
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
