import 'dart:io';
import 'models.dart';

List<WorkspaceInfo> scanWorkspaces() {
  final sutraDir = Directory('${Platform.environment['HOME']}/.sutra');
  if (!sutraDir.existsSync()) return [];

  final workspaces = <WorkspaceInfo>[];
  for (final entry in sutraDir.listSync()) {
    if (entry is! Directory) continue;
    final dbFile = File('${entry.path}/index.db');
    if (!dbFile.existsSync()) continue;
    workspaces.add(
      WorkspaceInfo(
        name: entry.uri.pathSegments.where((s) => s.isNotEmpty).last,
        dbPath: dbFile.path,
      ),
    );
  }
  workspaces.sort((a, b) => a.name.compareTo(b.name));
  return workspaces;
}
