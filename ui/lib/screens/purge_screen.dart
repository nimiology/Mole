import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class PurgeScreen extends ConsumerStatefulWidget {
  const PurgeScreen({super.key});

  @override
  ConsumerState<PurgeScreen> createState() => _PurgeScreenState();
}

class _PurgeScreenState extends ConsumerState<PurgeScreen> {
  bool _isLoading = false;
  String _output = '';

  final List<_ArtifactType> _artifactTypes = [
    _ArtifactType(
      'node_modules',
      Icons.javascript,
      AppColors.primary,
      '~2-4 GB per project',
    ),
    _ArtifactType(
      'target (Rust)',
      Icons.settings,
      AppColors.accentOrange,
      '~1-5 GB per project',
    ),
    _ArtifactType(
      'build',
      Icons.build,
      AppColors.accentBlue,
      '~0.5-2 GB per project',
    ),
    _ArtifactType(
      'dist',
      Icons.folder_zip,
      AppColors.accentPurple,
      '~100-500 MB per project',
    ),
    _ArtifactType(
      'venv / .venv',
      Icons.code,
      AppColors.accentTeal,
      '~200-800 MB per project',
    ),
    _ArtifactType(
      '.gradle',
      Icons.android,
      AppColors.accentYellow,
      '~500 MB-2 GB per project',
    ),
  ];

  Future<void> _runPurge() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });
    try {
      final service = ref.read(moleServiceProvider);
      final result = await service.purge();
      final cleanResult = result.replaceAll(
        RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'),
        '',
      );
      setState(() => _output = cleanResult);
    } catch (e) {
      setState(() => _output = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.folder_delete,
                  color: AppColors.accentTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Purge',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Remove old build artifacts from your projects',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _ScanButton(
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _runPurge,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Artifact type cards
          if (_output.isEmpty) ...[
            const Text(
              'Artifact types that will be scanned:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _artifactTypes
                  .map((t) => _ArtifactChip(type: t))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_delete_outlined,
                      size: 64,
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Click "Scan Projects" to find build artifacts',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.terminal,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Scan Results',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _output = ''),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textTertiary,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          _output,
                          style: const TextStyle(
                            fontFamily: 'Menlo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
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

class _ArtifactType {
  final String name;
  final IconData icon;
  final Color color;
  final String sizeHint;
  const _ArtifactType(this.name, this.icon, this.color, this.sizeHint);
}

class _ArtifactChip extends StatelessWidget {
  final _ArtifactType type;
  const _ArtifactChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: type.color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, color: type.color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.name,
                style: TextStyle(
                  color: type.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                type.sizeHint,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _ScanButton({required this.isLoading, this.onPressed});

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.onPressed != null
                ? (_hovered
                      ? AppColors.accentTeal
                      : AppColors.accentTeal.withValues(alpha: 0.8))
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered && widget.onPressed != null
                ? [
                    BoxShadow(
                      color: AppColors.accentTeal.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.search, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.isLoading ? 'Scanning...' : 'Scan Projects',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
