import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  String _currentPath = '';
  List<String> _pathSegments = [];
  List<_DirItem> _items = [];
  bool _isLoading = false;
  bool _hasScanned = false;
  int _totalSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _currentPath = Platform.environment['HOME'] ?? '/Users';
  }

  Future<void> _scanPath(String path) async {
    setState(() => _isLoading = true);
    final dir = Directory(path);
    if (!await dir.exists()) {
      setState(() => _isLoading = false);
      return;
    }

    final entries = await dir.list().toList();
    final items = <_DirItem>[];

    for (final entry in entries) {
      final name = entry.path.split('/').last;
      if (name.startsWith('.')) continue;

      int size = 0;
      bool isDir = entry is Directory;
      String type = isDir ? 'Folder' : _getFileType(name);

      if (entry is File) {
        try {
          size = await entry.length();
        } catch (_) {}
      } else if (isDir) {
        try {
          final children = await entry.list().take(200).toList();
          size = children.length * 4096;
        } catch (_) {}
      }

      items.add(
        _DirItem(
          name: name,
          path: entry.path,
          size: size,
          isDir: isDir,
          type: type,
        ),
      );
    }

    items.sort((a, b) => b.size.compareTo(a.size));
    final total = items.fold<int>(0, (sum, item) => sum + item.size);

    setState(() {
      _currentPath = path;
      _pathSegments = path.split('/')..removeWhere((s) => s.isEmpty);
      _items = items.take(50).toList();
      _totalSizeBytes = total;
      _isLoading = false;
      _hasScanned = true;
    });
  }

  String _getFileType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'Video File';
      case 'jpg':
      case 'png':
      case 'heic':
        return 'Image';
      case 'zip':
      case 'tar':
      case 'gz':
        return 'Archive';
      case 'pdf':
        return 'PDF';
      case 'dmg':
        return 'Disk Image';
      case 'pkg':
        return 'Package';
      default:
        return 'File';
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (bytes >= 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  Color _getSizeColor(int size) {
    if (_totalSizeBytes == 0) return AppColors.accentBlue;
    final fraction = size / _totalSizeBytes;
    if (fraction > 0.5) return AppColors.accentRed;
    if (fraction > 0.2) return AppColors.accentOrange;
    return AppColors.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb header
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x0D33C758))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_pathSegments.length > 1) {
                    final parent =
                        '/${_pathSegments.sublist(0, _pathSegments.length - 1).join('/')}';
                    _scanPath(parent);
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textSlate500,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Breadcrumb path
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < _pathSegments.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _scanPath(
                            '/${_pathSegments.sublist(0, i + 1).join('/')}',
                          ),
                          child: Text(
                            _pathSegments[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: i == _pathSegments.length - 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == _pathSegments.length - 1
                                  ? AppColors.textPrimary
                                  : AppColors.textSlate500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_hasScanned)
                GestureDetector(
                  onTap: () => _scanPath(_currentPath),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Scan',
                          style: TextStyle(
                            fontSize: 13,
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
        ),

        // Main content
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
                          Icons.radar,
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
                          'Analyzing Disk...',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSlate400,
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () => _scanPath(_currentPath),
                          icon: const Icon(Icons.search),
                          label: const Text('Analyze Drive'),
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
              : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView(
                  padding: const EdgeInsets.all(32),
                  children: [
                    Text(
                      'Analyze',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSlate500,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Visualize disk usage and find large files in ',
                          ),
                          TextSpan(
                            text:
                                '/${_pathSegments.isNotEmpty ? _pathSegments.last : ''}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Table header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 5,
                            child: Text(
                              'NAME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSlate400,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 5,
                            child: Center(
                              child: Text(
                                'VISUAL SIZE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSlate400,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 100,
                            child: Text(
                              'CAPACITY',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSlate400,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0x0D33C758), height: 1),
                    const SizedBox(height: 4),

                    // Items
                    ...List.generate(
                      _items.length,
                      (i) => _ItemRow(
                        item: _items[i],
                        color: _getSizeColor(_items[i].size),
                        fraction: _totalSizeBytes > 0
                            ? _items[i].size / _totalSizeBytes
                            : 0,
                        formattedSize: _formatSize(_items[i].size),
                        onTap: _items[i].isDir
                            ? () => _scanPath(_items[i].path)
                            : null,
                      ),
                    ),
                  ],
                ),
        ),

        // Footer
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: const Border(top: BorderSide(color: Color(0x0D33C758))),
          ),
          child: Row(
            children: [
              Text(
                '${_items.length} ITEMS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate400,
                  letterSpacing: 1,
                ),
              ),
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  color: AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                '${_formatSize(_totalSizeBytes)} TOTAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate400,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'SCAN COMPLETED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Models ──────────────────────────────

class _DirItem {
  final String name;
  final String path;
  final int size;
  final bool isDir;
  final String type;
  const _DirItem({
    required this.name,
    required this.path,
    required this.size,
    required this.isDir,
    required this.type,
  });
}

// ─── Item Row ────────────────────────────

class _ItemRow extends StatefulWidget {
  final _DirItem item;
  final Color color;
  final double fraction;
  final String formattedSize;
  final VoidCallback? onTap;
  const _ItemRow({
    required this.item,
    required this.color,
    required this.fraction,
    required this.formattedSize,
    this.onTap,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isBig = widget.fraction > 0.2;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Icon + name
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.item.isDir ? Icons.folder : Icons.description,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _hovered
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.item.type,
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
              // Size bar
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.fraction.clamp(0.01, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(widget.color),
                    ),
                  ),
                ),
              ),
              // Size text
              SizedBox(
                width: 100,
                child: Text(
                  widget.formattedSize,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBig ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'Menlo',
                    color: isBig ? widget.color : AppColors.textSlate500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
