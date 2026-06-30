import 'dart:io';

import 'process_runner.dart';

enum ReleaseChannel { stable, beta }

enum BumpKind { patch, minor, major }

Future<String> computeNextVersion({
  required ReleaseChannel channel,
  required BumpKind bump,
  required String pubspecPath,
}) async {
  final pubspec = File(pubspecPath);
  if (!pubspec.existsSync()) {
    throw StateError('pubspec.yaml missing at $pubspecPath');
  }

  final text = pubspec.readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(text);
  if (match == null) {
    throw StateError('pubspec.yaml missing version:');
  }

  final current = match.group(1)!;
  final currentBase = current.split('-').first;

  try {
    await runProcess('git', ['fetch', '--tags', '--force']);
  } catch (_) {}

  final tagsOutput = await runProcessOutput('git', ['tag', '-l', 'v*']);
  final tags = tagsOutput.split('\n').where((t) => t.isNotEmpty).toList();

  final stableTags =
      tags
          .where((t) => !t.contains('-beta'))
          .map((t) => t.substring(1))
          .toList()
        ..sort((a, b) => _compareStable(a, b));

  final betaTags = tags
      .where((t) => t.contains('-beta'))
      .map((t) => t.substring(1))
      .toList();

  final List<int> baseParts;
  if (stableTags.isNotEmpty) {
    baseParts = _parseStable(stableTags.last.split('-').first);
  } else {
    baseParts = _parseStable(currentBase);
  }

  final nextStableParts = _bumpStable(baseParts, bump);
  final nextStable = nextStableParts.join('.');

  if (channel == ReleaseChannel.stable) {
    return nextStable;
  }

  final prefix = '$nextStable-beta.';
  final existing = betaTags
      .where((t) => t.startsWith(prefix))
      .map((t) => t.substring(prefix.length))
      .where((n) => RegExp(r'^\d+$').hasMatch(n))
      .map(int.parse)
      .toList();

  final nextN = existing.isEmpty
      ? 1
      : existing.reduce((a, b) => a > b ? a : b) + 1;
  return '$nextStable-beta.$nextN';
}

List<int> _parseStable(String base) {
  return base.split('.').map(int.parse).toList();
}

List<int> _bumpStable(List<int> parts, BumpKind bump) {
  final major = parts[0];
  final minor = parts.length > 1 ? parts[1] : 0;
  final patch = parts.length > 2 ? parts[2] : 0;

  return switch (bump) {
    BumpKind.major => [major + 1, 0, 0],
    BumpKind.minor => [major, minor + 1, 0],
    BumpKind.patch => [major, minor, patch + 1],
  };
}

int _compareStable(String a, String b) {
  final pa = _parseStable(a.split('-').first);
  final pb = _parseStable(b.split('-').first);
  for (var i = 0; i < 3; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

ReleaseChannel parseChannel(String value) {
  return switch (value) {
    'stable' => ReleaseChannel.stable,
    'beta' => ReleaseChannel.beta,
    _ => throw ArgumentError('--channel must be stable or beta'),
  };
}

BumpKind parseBump(String value) {
  return switch (value) {
    'patch' => BumpKind.patch,
    'minor' => BumpKind.minor,
    'major' => BumpKind.major,
    _ => throw ArgumentError('--bump must be patch, minor, or major'),
  };
}
