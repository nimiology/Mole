import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/mole_provider.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(systemStatusProvider);

    return statusAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Collecting system metrics...',
              style: TextStyle(color: AppColors.textSlate500),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.accentRed),
        ),
      ),
      data: (data) => _StatusDashboard(data: data),
    );
  }
}

class _StatusDashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatusDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cpu = data['cpu'] as Map<String, dynamic>? ?? {};
    final memory = data['memory'] as Map<String, dynamic>? ?? {};
    final disk = data['disk'] as Map<String, dynamic>? ?? {};
    final battery = data['battery'] as Map<String, dynamic>? ?? {};

    final cpuUsage = (cpu['usage'] as num?)?.toDouble() ?? 0;
    final memUsed = (memory['used'] as num?)?.toDouble() ?? 0;
    final memTotal = (memory['total'] as num?)?.toDouble() ?? 16;
    final memPct = (memory['usedPercent'] as num?)?.toDouble() ?? 0;
    final diskPct =
        double.tryParse(disk['usedPercent']?.toString() ?? '0') ?? 0;
    final batteryPct = (battery['percent'] as num?)?.toInt() ?? 88;
    final batteryCharging = battery['charging'] as bool? ?? false;

    double healthScore = 100;
    if (cpuUsage > 30) healthScore -= (cpuUsage - 30) * 0.4;
    if (memPct > 50) healthScore -= (memPct - 50) * 0.3;
    if (diskPct > 70) healthScore -= (diskPct - 70) * 0.5;
    healthScore = healthScore.clamp(0, 100);

    String healthLabel = healthScore >= 80
        ? 'EXCELLENT'
        : healthScore >= 60
        ? 'GOOD'
        : 'WARNING';

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      children: [
        // Header
        Text('Status', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        const Text(
          'Real-time system health monitoring',
          style: TextStyle(fontSize: 13, color: AppColors.textSlate500),
        ),
        const SizedBox(height: 24),

        // Hero health ring — glass card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0x991C1C1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            children: [
              // Ring
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _HealthRingPainter(score: healthScore / 100),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${healthScore.toInt()}%',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          healthLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Stats row
              Container(
                padding: const EdgeInsets.only(top: 32),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatPill('UPTIME', '12d 4h 32m'),
                    _StatPill('AVG TEMP', '42°C'),
                    _StatPill('TASKS', '342 Active'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 metric cards
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // CPU
              Expanded(
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CPU Usage',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cpuUsage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.memory,
                            color: AppColors.textSlate400,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _CpuSparkline()),
                      const SizedBox(height: 8),
                      Text(
                        'APPLE M3 PRO (12-CORE)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Memory
              Expanded(
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Memory',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${memUsed.toStringAsFixed(1)} ',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'GB',
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
                          const Icon(
                            Icons.settings_input_component,
                            color: AppColors.textSlate400,
                            size: 20,
                          ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: memPct / 100,
                          minHeight: 10,
                          backgroundColor: const Color(0x0DFFFFFF),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.accentPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'USED ${memUsed.toStringAsFixed(1)}GB',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate500,
                            ),
                          ),
                          Text(
                            'TOTAL ${memTotal.toStringAsFixed(1)}GB',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'LPDDR5 UNIFIED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Disk
              Expanded(
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Disk',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${disk['free'] ?? '412'} ',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'GB Free',
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
                          const Icon(
                            Icons.storage,
                            color: AppColors.textSlate400,
                            size: 20,
                          ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 45,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Container(
                                  color: const Color(0x1AFFFFFF),
                                ),
                              ),
                              Expanded(
                                flex: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0x0DFFFFFF),
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SYSTEM ${diskPct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate500,
                            ),
                          ),
                          Text(
                            'OTHER 12%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'MACINTOSH HD (SSD)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Battery
              Expanded(
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battery',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '$batteryPct%',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (batteryCharging) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.bolt,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.battery_charging_full,
                            color: AppColors.textSlate400,
                            size: 20,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x0DFFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Condition: Normal',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 2),
                              child: Text(
                                'Cycle Count: 142',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'POWER: ADAPTER CONNECTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // System logs + Security
        SizedBox(
          height: 240,
          child: Row(
            children: [
              // Recent system logs
              Expanded(
                flex: 2,
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent System Logs',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LogItem(
                        Icons.check_circle,
                        AppColors.primary,
                        'System backup completed',
                        'iCloud Storage • 2 mins ago',
                        'PID: 1042',
                      ),
                      const Divider(color: Color(0x0DFFFFFF), height: 16),
                      _LogItem(
                        Icons.sync,
                        AppColors.accentPurple,
                        'Network handshake renewed',
                        'Wi-Fi Interface • 15 mins ago',
                        'PID: 981',
                      ),
                      const Divider(color: Color(0x0DFFFFFF), height: 16),
                      _LogItem(
                        Icons.warning,
                        AppColors.accentOrange,
                        'High memory usage detected',
                        'Photoshop.app • 42 mins ago',
                        'PID: 2284',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Security status
              Expanded(
                child: _GlassCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Security Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your firewall is active and 4 systems are protected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSlate500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RISK LEVEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'VERY LOW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.08,
                          minHeight: 6,
                          backgroundColor: Color(0x0DFFFFFF),
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x991C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );
  }
}

class _LogItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String pid;
  const _LogItem(this.icon, this.color, this.title, this.subtitle, this.pid);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: AppColors.textSlate500),
              ),
            ],
          ),
        ),
        Text(
          pid,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Menlo',
            color: AppColors.textSlate500,
          ),
        ),
      ],
    );
  }
}

class _CpuSparkline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), (20 + (i * 7 % 35)).toDouble()),
    );
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  final double score;
  _HealthRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final bgPaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Glow
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, bgPaint);
    final sweepAngle = 2 * math.pi * score;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter old) => old.score != score;
}
