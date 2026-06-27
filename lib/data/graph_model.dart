import 'db_connection.dart';
import 'health_scoring.dart';

class ComponentNode {
  final String id;
  final String name;
  final int fileCount;
  final int lineCount;
  final double healthScore;

  const ComponentNode({
    required this.id,
    required this.name,
    required this.fileCount,
    required this.lineCount,
    required this.healthScore,
  });
}

class ComponentEdge {
  final String sourceId;
  final String targetId;
  final int weight;

  const ComponentEdge({
    required this.sourceId,
    required this.targetId,
    required this.weight,
  });
}

class ComponentGraph {
  final List<ComponentNode> nodes;
  final List<ComponentEdge> edges;

  const ComponentGraph({required this.nodes, required this.edges});
}

ComponentGraph buildComponentGraph(DbConnection db) {
  final rawComponents = db.queryComponents();
  if (rawComponents.isEmpty) {
    return const ComponentGraph(nodes: [], edges: []);
  }

  final findings = db.queryHealthFindings();
  final membership = db.queryComponentMembership();

  // Group findings by file_id
  final findingsByFile = <int, List<Map<String, dynamic>>>{};
  for (final f in findings) {
    final fileId = f['file_id'] as int;
    (findingsByFile[fileId] ??= []).add(f);
  }

  // Compute per-file health scores
  final fileScores = <int, double>{};
  for (final entry in findingsByFile.entries) {
    fileScores[entry.key] = scoreFile(entry.value);
  }

  // Group membership by component, collect (score, lineCount) pairs
  final compFileScores = <String, List<(double, int)>>{};
  for (final m in membership) {
    final compId = m['component_id'] as String;
    final fileId = m['file_id'] as int;
    final lineCount = m['line_count'] as int;
    final score = fileScores[fileId] ?? 10.0;
    (compFileScores[compId] ??= []).add((score, lineCount));
  }

  // Build nodes
  final nodes = <ComponentNode>[];
  for (final c in rawComponents) {
    final id = c['id'] as String;
    nodes.add(
      ComponentNode(
        id: id,
        name: c['name'] as String,
        fileCount: c['file_count'] as int,
        lineCount: (c['total_lines'] as int),
        healthScore: scoreComponent(compFileScores[id] ?? []),
      ),
    );
  }

  // Build edges
  final rawEdges = db.queryCrossComponentEdges();
  final nodeIds = {for (final n in nodes) n.id};
  final edges = <ComponentEdge>[];
  for (final e in rawEdges) {
    final src = e['source_id'] as String;
    final tgt = e['target_id'] as String;
    if (nodeIds.contains(src) && nodeIds.contains(tgt)) {
      edges.add(
        ComponentEdge(sourceId: src, targetId: tgt, weight: e['weight'] as int),
      );
    }
  }

  return ComponentGraph(nodes: nodes, edges: edges);
}
