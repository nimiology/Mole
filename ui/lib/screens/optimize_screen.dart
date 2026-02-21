import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class OptimizeScreen extends ConsumerStatefulWidget {
  const OptimizeScreen({super.key});

  @override
  ConsumerState<OptimizeScreen> createState() => _OptimizeScreenState();
}

class _OptimizeScreenState extends ConsumerState<OptimizeScreen> {
  bool _isRunning = false;
  final List<_Task> _tasks = [
    _Task(
      'Rebuild Spotlight Index',
      'Re-indexes files for faster search results and improved system performance.',
      false,
      0,
    ),
    _Task(
      'Reset Network Settings',
      'Clears saved configurations and temporary caches to fix connectivity issues.',
      false,
      0,
    ),
    _Task(
      'Clear Swap Files',
      'Reclaims disk space used by virtual memory systems and old cache files.',
      false,
      0,
    ),
    _Task(
      'Flush DNS Cache',
      'Clears local DNS data to resolve website loading issues and redirects.',
      false,
      0,
    ),
    _Task(
      'Repair Disk Permissions',
      'Ensures file system integrity and proper application access rights.',
      false,
      0,
    ),
  ];

  bool get _selectAll => _tasks.every((t) => t.checked);
  int get _completedCount => _tasks.where((t) => t.progress >= 1.0).length;
  double get _overallProgress =>
      _tasks.isEmpty ? 0 : _completedCount / _tasks.length;

  Future<void> _runOptimize() async {
    setState(() => _isRunning = true);
    try {
      final service = ref.read(moleServiceProvider);
      await service.optimize();
      // Mark all tasks as done
      setState(() {
        for (int i = 0; i < _tasks.length; i++) {
          _tasks[i] = _tasks[i].copyWith(progress: 1.0);
        }
      });
    } catch (_) {}
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optimize',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Refresh system services and maintenance databases.',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSlate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RunButton(
                    isRunning: _isRunning,
                    onPressed: _isRunning ? null : _runOptimize,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Checklist header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MAINTENANCE TASKS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate400,
                        letterSpacing: 1.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final newVal = !_selectAll;
                        setState(() {
                          for (int i = 0; i < _tasks.length; i++) {
                            _tasks[i] = _tasks[i].copyWith(checked: newVal);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          _OrangeCheckbox(checked: _selectAll),
                          const SizedBox(width: 8),
                          Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Task list
              ...List.generate(_tasks.length, (i) {
                final task = _tasks[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TaskCard(
                    task: task,
                    onToggle: () => setState(
                      () => _tasks[i] = task.copyWith(checked: !task.checked),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Overall progress bar
              _OverallProgress(
                completedCount: _completedCount,
                totalCount: _tasks.length,
                progress: _overallProgress,
              ),
            ],
          ),
        ),

        // Footer status bar
        _FooterStatusBar(),
      ],
    );
  }
}

// ─── Models ──────────────────────────────

class _Task {
  final String title;
  final String description;
  final bool checked;
  final double progress;
  const _Task(this.title, this.description, this.checked, this.progress);
  _Task copyWith({bool? checked, double? progress}) => _Task(
    title,
    description,
    checked ?? this.checked,
    progress ?? this.progress,
  );
}

// ─── Orange Checkbox ─────────────────────

class _OrangeCheckbox extends StatelessWidget {
  final bool checked;
  const _OrangeCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.accentOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: checked ? AppColors.accentOrange : AppColors.textTertiary,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

// ─── Task Card ───────────────────────────

class _TaskCard extends StatefulWidget {
  final _Task task;
  final VoidCallback onToggle;
  const _TaskCard({required this.task, required this.onToggle});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDone = widget.task.progress >= 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.accentOrange.withValues(alpha: 0.5)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onToggle,
              child: _OrangeCheckbox(checked: widget.task.checked),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Mini progress ring
            _MiniProgressRing(
              progress: widget.task.progress,
              label: '${(widget.task.progress * 100).toInt()}%',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini Progress Ring ──────────────────

class _MiniProgressRing extends StatelessWidget {
  final double progress;
  final String label;
  const _MiniProgressRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48, 48),
            painter: _RingPainter(
              progress: progress,
              bgColor: AppColors.border,
              fgColor: progress > 0
                  ? AppColors.primary
                  : AppColors.accentOrange,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: progress > 0
                  ? AppColors.textPrimary
                  : AppColors.textSlate400,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  _RingPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ─── Overall Progress ────────────────────

class _OverallProgress extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double progress;
  const _OverallProgress({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pending = totalCount - completedCount;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: AppColors.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completedCount == totalCount
                          ? 'All tasks complete!'
                          : 'Ready to optimize',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    Text(
                      '$pending tasks pending, $completedCount completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentOrange),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Run button ──────────────────────────

class _RunButton extends StatefulWidget {
  final bool isRunning;
  final VoidCallback? onPressed;
  const _RunButton({required this.isRunning, this.onPressed});

  @override
  State<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends State<_RunButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF97316) : AppColors.accentOrange,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isRunning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.isRunning ? 'Running...' : 'Run All Tasks',
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

// ─── Footer Status Bar ───────────────────

class _FooterStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _StatusDot(AppColors.primary, 'SYSTEM STABLE'),
          const SizedBox(width: 24),
          _StatusDot(AppColors.accentOrange, 'CPU 12%'),
          const SizedBox(width: 24),
          _StatusDot(AppColors.accentBlue, 'RAM 4.2GB FREE'),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.refresh, size: 14, color: AppColors.textSlate400),
              const SizedBox(width: 4),
              Text(
                'LAST SCAN: 2 HOURS AGO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate400,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
