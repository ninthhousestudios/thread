class WorkspaceInfo {
  final String name;
  final String dbPath;

  const WorkspaceInfo({required this.name, required this.dbPath});
}

class WorkspaceStats {
  final String name;
  final int fileCount;
  final int symbolCount;
  final DateTime? lastParsed;

  const WorkspaceStats({
    required this.name,
    required this.fileCount,
    required this.symbolCount,
    this.lastParsed,
  });
}
