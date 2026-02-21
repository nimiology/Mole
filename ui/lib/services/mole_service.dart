import 'dart:async';
import 'dart:io';

/// Thin wrapper around the `mo` CLI binary.
/// Calls `mo` commands via Process.run/start and returns raw stdout.
class MoleService {
  /// Locates the `mole` CLI. Checks project root first, then common install paths.
  Future<String> _findMoBinary() async {
    // Check common paths — project root first
    final paths = [
      // Project root (development mode)
      '${Platform.resolvedExecutable.split('/ui/').first}/mole',
      '${Platform.environment['HOME']}/Development/Mole/mole',
      // System-wide install paths
      '/usr/local/bin/mole',
      '/opt/homebrew/bin/mole',
      '${Platform.environment['HOME']}/.local/bin/mole',
      '/usr/local/bin/mo',
      '/opt/homebrew/bin/mo',
      '${Platform.environment['HOME']}/.local/bin/mo',
    ];
    for (final p in paths) {
      if (await File(p).exists()) return p;
    }
    // Fall back to PATH
    return 'mole';
  }

  /// Run a `mo` command and return stdout.
  Future<String> runCommand(List<String> args) async {
    final binary = await _findMoBinary();
    final result = await Process.run(
      binary,
      args,
      environment: {...Platform.environment, 'NO_COLOR': '1', 'TERM': 'dumb'},
    );
    if (result.exitCode != 0 && (result.stderr as String).isNotEmpty) {
      throw MoleException(
        'mo ${args.join(' ')} failed (exit ${result.exitCode})',
        result.stderr as String,
      );
    }
    return result.stdout as String;
  }

  /// Run a `mole` command and stream stdout live line-by-line.
  Stream<String> runCommandStream(List<String> args) async* {
    final binary = await _findMoBinary();
    final process = await Process.start(
      binary,
      args,
      environment: {...Platform.environment, 'NO_COLOR': '1', 'TERM': 'dumb'},
    );

    // Yield stdout line by line
    await for (final line in process.stdout.transform(
      SystemEncoding().decoder,
    )) {
      yield line;
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final stderr = await process.stderr
          .transform(SystemEncoding().decoder)
          .join();
      if (stderr.isNotEmpty) {
        throw MoleException(
          'mole ${args.join(' ')} failed (exit $exitCode)',
          stderr,
        );
      }
    }
  }

  /// Run `mole clean --dry-run` to preview cleanup (streaming).
  Stream<String> cleanDryRunStream() =>
      runCommandStream(['clean', '--dry-run']);

  /// Run `mole clean` to perform cleanup (streaming).
  Stream<String> cleanStream() => runCommandStream(['clean']);

  /// Run `mo uninstall` — returns app list or triggers interactive mode.
  Future<String> uninstall() => runCommand(['uninstall']);

  /// Run `mo optimize --dry-run` to preview optimization.
  Future<String> optimizeDryRun() => runCommand(['optimize', '--dry-run']);

  /// Run `mo optimize`.
  Future<String> optimize() => runCommand(['optimize']);

  /// Run `mo analyze` for disk analysis.
  Future<String> analyze([String? path]) =>
      runCommand(['analyze', if (path != null) path]);

  /// Run `mo purge` for project artifact cleanup.
  Future<String> purge() => runCommand(['purge']);

  /// Run `mo installer` for installer cleanup.
  Future<String> installer() => runCommand(['installer']);

  /// Get Mole version.
  Future<String> version() async {
    final output = await runCommand(['--version']);
    return output.trim();
  }

  /// Check if `mo` is installed and available.
  Future<bool> isAvailable() async {
    try {
      await version();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get system status info by reading system_profiler and sysctl.
  Future<Map<String, dynamic>> getSystemStatus() async {
    final results = await Future.wait([
      _getCPUUsage(),
      _getMemoryInfo(),
      _getDiskInfo(),
      _getBatteryInfo(),
    ]);
    return {
      'cpu': results[0],
      'memory': results[1],
      'disk': results[2],
      'battery': results[3],
    };
  }

  Future<Map<String, dynamic>> _getCPUUsage() async {
    try {
      final result = await Process.run(
        'top',
        ['-l', '1', '-n', '0', '-stats', 'cpu'],
        environment: {'TERM': 'dumb'},
      );
      final output = result.stdout as String;
      final lines = output.split('\n');
      double userPct = 0, sysPct = 0, idlePct = 100;
      for (final line in lines) {
        if (line.contains('CPU usage:')) {
          final re = RegExp(r'([\d.]+)% user.*?([\d.]+)% sys.*?([\d.]+)% idle');
          final match = re.firstMatch(line);
          if (match != null) {
            userPct = double.tryParse(match.group(1)!) ?? 0;
            sysPct = double.tryParse(match.group(2)!) ?? 0;
            idlePct = double.tryParse(match.group(3)!) ?? 100;
          }
          break;
        }
      }
      return {
        'usage': userPct + sysPct,
        'user': userPct,
        'system': sysPct,
        'idle': idlePct,
      };
    } catch (_) {
      return {'usage': 0.0, 'user': 0.0, 'system': 0.0, 'idle': 100.0};
    }
  }

  Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      final result = await Process.run('vm_stat', []);
      final output = result.stdout as String;
      final lines = output.split('\n');
      int pageSize = 16384;
      int free = 0, active = 0, inactive = 0, wired = 0, speculative = 0;

      final sizeMatch = RegExp(r'page size of (\d+)').firstMatch(output);
      if (sizeMatch != null) pageSize = int.parse(sizeMatch.group(1)!);

      for (final line in lines) {
        if (line.startsWith('Pages free:')) {
          free = _parseStat(line);
        } else if (line.startsWith('Pages active:')) {
          active = _parseStat(line);
        } else if (line.startsWith('Pages inactive:')) {
          inactive = _parseStat(line);
        } else if (line.startsWith('Pages wired down:')) {
          wired = _parseStat(line);
        } else if (line.startsWith('Pages speculative:')) {
          speculative = _parseStat(line);
        }
      }

      // Get total memory from sysctl
      final sysctlResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      final totalBytes =
          int.tryParse((sysctlResult.stdout as String).trim()) ?? 0;
      final usedPages = active + wired + speculative;
      final usedBytes = usedPages * pageSize;
      final totalGB = totalBytes / (1024 * 1024 * 1024);
      final usedGB = usedBytes / (1024 * 1024 * 1024);

      return {
        'total': totalGB,
        'used': usedGB,
        'free': (free + inactive) * pageSize / (1024 * 1024 * 1024),
        'usedPercent': totalBytes > 0 ? (usedBytes / totalBytes * 100) : 0.0,
      };
    } catch (_) {
      return {'total': 0.0, 'used': 0.0, 'free': 0.0, 'usedPercent': 0.0};
    }
  }

  int _parseStat(String line) {
    final match = RegExp(r':\s+(\d+)').firstMatch(line);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<Map<String, dynamic>> _getDiskInfo() async {
    try {
      final result = await Process.run('df', ['-h', '/']);
      final output = result.stdout as String;
      final lines = output.split('\n');
      if (lines.length >= 2) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          return {
            'total': parts[1],
            'used': parts[2],
            'free': parts[3],
            'usedPercent': parts[4].replaceAll('%', ''),
          };
        }
      }
      return {'total': '0', 'used': '0', 'free': '0', 'usedPercent': '0'};
    } catch (_) {
      return {'total': '0', 'used': '0', 'free': '0', 'usedPercent': '0'};
    }
  }

  Future<Map<String, dynamic>> _getBatteryInfo() async {
    try {
      final result = await Process.run('pmset', ['-g', 'batt']);
      final output = result.stdout as String;
      final match = RegExp(r'(\d+)%').firstMatch(output);
      final pct = match != null ? int.parse(match.group(1)!) : -1;
      final isCharging =
          output.contains('charging') || output.contains('AC Power');
      return {'percent': pct, 'charging': isCharging, 'available': pct >= 0};
    } catch (_) {
      return {'percent': -1, 'charging': false, 'available': false};
    }
  }
}

class MoleException implements Exception {
  final String message;
  final String stderr;
  MoleException(this.message, this.stderr);
  @override
  String toString() => 'MoleException: $message\n$stderr';
}
