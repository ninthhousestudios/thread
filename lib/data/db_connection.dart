import 'package:sqlite3/sqlite3.dart';
import 'models.dart';

class DbConnection {
  Database? _db;

  String? get activePath => _db != null ? _path : null;
  String? _path;

  void open(String dbPath) {
    _db?.close();
    _db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    _path = dbPath;
  }

  void close() {
    _db?.close();
    _db = null;
    _path = null;
  }

  WorkspaceStats queryStats(String workspaceName) {
    final db = _db;
    if (db == null) {
      return WorkspaceStats(name: workspaceName, fileCount: 0, symbolCount: 0);
    }

    final fileCount =
        db.select('SELECT COUNT(*) as c FROM files').first['c'] as int;

    int symbolCount = 0;
    if (_hasTable(db, 'symbols')) {
      symbolCount =
          db.select('SELECT COUNT(*) as c FROM symbols').first['c'] as int;
    }

    DateTime? lastParsed;
    final lastParsedResult = db.select(
      'SELECT MAX(last_parsed) as lp FROM files',
    );
    final lpValue = lastParsedResult.first['lp'];
    if (lpValue != null) {
      if (lpValue is int) {
        lastParsed = DateTime.fromMillisecondsSinceEpoch(lpValue);
      } else if (lpValue is String) {
        lastParsed = DateTime.tryParse(lpValue);
      }
    }

    return WorkspaceStats(
      name: workspaceName,
      fileCount: fileCount,
      symbolCount: symbolCount,
      lastParsed: lastParsed,
    );
  }

  List<Map<String, dynamic>> queryComponents() {
    final db = _db;
    if (db == null || !_hasTable(db, 'components')) return [];
    return _toMaps(
      db.select('''
        SELECT c.id, c.name,
               COUNT(cm.file_id) AS file_count,
               COALESCE(SUM(f.line_count), 0) AS total_lines
        FROM components c
        JOIN component_membership cm ON cm.component_id = c.id
        JOIN files f ON f.id = cm.file_id
        WHERE c.dissolved_at IS NULL
        GROUP BY c.id, c.name
        ORDER BY c.name
      '''),
    );
  }

  List<Map<String, dynamic>> queryHealthFindings() {
    final db = _db;
    if (db == null || !_hasTable(db, 'health_findings')) return [];
    return _toMaps(
      db.select('''
        SELECT hf.file_id, hf.biomarker_kind, hf.severity
        FROM health_findings hf
        WHERE NOT EXISTS (
          SELECT 1 FROM health_waivers hw
          JOIN files f ON f.path = hw.file_path
          WHERE f.id = hf.file_id AND hw.biomarker_kind = hf.biomarker_kind
        )
      '''),
    );
  }

  List<Map<String, dynamic>> queryCrossComponentEdges() {
    final db = _db;
    if (db == null || !_hasTable(db, 'component_membership')) return [];
    return _toMaps(
      db.select('''
        SELECT cm1.component_id AS source_id,
               cm2.component_id AS target_id,
               COUNT(*) AS weight
        FROM refs r
        JOIN symbols s ON s.id = r.target_symbol_id
        JOIN component_membership cm1 ON cm1.file_id = r.file_id
        JOIN component_membership cm2 ON cm2.file_id = s.file_id
        WHERE r.target_symbol_id IS NOT NULL
          AND cm1.component_id != cm2.component_id
        GROUP BY cm1.component_id, cm2.component_id
      '''),
    );
  }

  List<Map<String, dynamic>> queryComponentMembership() {
    final db = _db;
    if (db == null || !_hasTable(db, 'component_membership')) return [];
    return _toMaps(
      db.select('''
        SELECT cm.component_id, cm.file_id, f.line_count
        FROM component_membership cm
        JOIN files f ON f.id = cm.file_id
        JOIN components c ON c.id = cm.component_id
        WHERE c.dissolved_at IS NULL
      '''),
    );
  }

  bool _hasTable(Database db, String table) {
    final result = db.select(
      "SELECT COUNT(*) as c FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return (result.first['c'] as int) > 0;
  }

  static List<Map<String, dynamic>> _toMaps(ResultSet rs) {
    return [
      for (final row in rs) {for (final col in row.keys) col: row[col]},
    ];
  }
}
