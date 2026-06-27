import 'package:sqlite3/sqlite3.dart';
import 'models.dart';

class DbConnection {
  Database? _db;

  String? get activePath => _db != null ? _path : null;
  String? _path;

  void open(String dbPath) {
    _db?.dispose();
    _db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    _path = dbPath;
  }

  void close() {
    _db?.dispose();
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

  bool _hasTable(Database db, String table) {
    final result = db.select(
      "SELECT COUNT(*) as c FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return (result.first['c'] as int) > 0;
  }
}
