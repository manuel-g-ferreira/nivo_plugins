import 'dart:io';

String extractChangelog(String version, {String filePath = 'CHANGELOG.md'}) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw StateError('Missing $filePath');
  }

  final lines = file.readAsStringSync().split('\n');
  final headerPattern = RegExp(
    r'^## \[(' +
        RegExp.escape(version) +
        r')\]( |$)|^## ' +
        RegExp.escape(version) +
        r'([^0-9]|$)',
  );

  if (!lines.any((line) => headerPattern.hasMatch(line))) {
    throw StateError(
      'CHANGELOG.md has no section for version $version (expected ## [$version])',
    );
  }

  final buffer = StringBuffer();
  var capturing = false;

  for (final line in lines) {
    if (headerPattern.hasMatch(line)) {
      capturing = true;
      continue;
    }
    if (capturing && line.startsWith('## ')) {
      break;
    }
    if (capturing) {
      buffer.writeln(line);
    }
  }

  return buffer.toString().replaceFirst(RegExp(r'\n$'), '');
}

void updateChangelog({
  required String version,
  required String date,
  required String notes,
  String filePath = 'CHANGELOG.md',
}) {
  final file = File(filePath);
  const unreleasedHeader = '## [Unreleased]';
  var text = file.readAsStringSync();

  if (!text.contains(unreleasedHeader)) {
    throw StateError('CHANGELOG.md missing ## [Unreleased]');
  }

  final parts = text.split(unreleasedHeader);
  final before = parts.first;
  var rest = parts
      .sublist(1)
      .join(unreleasedHeader)
      .replaceFirst(RegExp(r'^\n+'), '');

  final extraBlocks = <String>[];
  var releasedSections = '';

  if (rest.isNotEmpty && !rest.startsWith('## ')) {
    final sectionSplit = rest.split('\n## ');
    final unreleasedBody = sectionSplit.first;
    final extra = unreleasedBody.trim();
    if (extra.isNotEmpty) {
      extraBlocks.add(extra);
    }
    if (sectionSplit.length > 1) {
      releasedSections = '## ${sectionSplit.sublist(1).join('\n## ')}';
    }
  } else if (rest.startsWith('## ')) {
    releasedSections = rest;
  }

  var newSection = '## [$version] - $date\n\n${notes.trimRight()}';
  if (extraBlocks.isNotEmpty) {
    newSection += '\n\n${extraBlocks.join('\n\n')}';
  }

  final updated = StringBuffer()
    ..write(before.trimRight())
    ..writeln()
    ..writeln()
    ..writeln(unreleasedHeader)
    ..writeln()
    ..writeln(newSection)
    ..writeln();

  if (releasedSections.trim().isNotEmpty) {
    updated.writeln();
    updated.write(releasedSections.replaceFirst(RegExp(r'^\n+'), ''));
  }

  file.writeAsStringSync(updated.toString());
}
