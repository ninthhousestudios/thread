import 'dart:math' as math;
import 'dart:ui';

import '../data/graph_model.dart';
import 'layout_engine.dart';

class ForceDirectedLayout implements LayoutEngine {
  static const _repulsion = 60.0;
  static const _springLength = 120.0;
  static const _springConstant = 0.08;
  static const _damping = 0.4;
  static const _centralGravity = 0.005;
  static const _iterations = 200;
  static const _padding = 60.0;
  static const _minRadius = 20.0;
  static const _maxRadius = 50.0;

  @override
  List<PositionedNode> layout(ComponentGraph graph, Size canvasSize) {
    final n = graph.nodes.length;
    if (n == 0) return [];

    if (n == 1) {
      final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
      return [
        PositionedNode(
          node: graph.nodes[0],
          position: center,
          radius: (_minRadius + _maxRadius) / 2,
        ),
      ];
    }

    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    // Deterministic initialization: golden angle spiral
    const goldenAngle = 2.399963229728653; // pi * (3 - sqrt(5))
    final positions = List<Offset>.generate(n, (i) {
      final r = 50.0 * math.sqrt(i + 1);
      final theta = i * goldenAngle;
      return Offset(cx + r * math.cos(theta), cy + r * math.sin(theta));
    });

    final velocities = List<Offset>.filled(n, Offset.zero);

    // Build adjacency for quick lookup
    final adjacency = <int, List<(int, double)>>{};
    for (final edge in graph.edges) {
      final si = graph.nodes.indexWhere((n) => n.id == edge.sourceId);
      final ti = graph.nodes.indexWhere((n) => n.id == edge.targetId);
      if (si >= 0 && ti >= 0) {
        (adjacency[si] ??= []).add((ti, edge.weight.toDouble()));
        (adjacency[ti] ??= []).add((si, edge.weight.toDouble()));
      }
    }

    for (var iter = 0; iter < _iterations; iter++) {
      final forces = List<Offset>.filled(n, Offset.zero);

      // Repulsion between all pairs
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          var delta = positions[i] - positions[j];
          var dist = delta.distance;
          if (dist < 1.0) {
            delta = const Offset(1.0, 0.0);
            dist = 1.0;
          }
          final force = _repulsion / (dist * dist);
          final f = delta / dist * force;
          forces[i] = forces[i] + f;
          forces[j] = forces[j] - f;
        }
      }

      // Spring attraction along edges
      for (final entry in adjacency.entries) {
        final i = entry.key;
        for (final (j, _) in entry.value) {
          if (i >= j) continue;
          final delta = positions[j] - positions[i];
          final dist = delta.distance;
          if (dist < 0.1) continue;
          final displacement = dist - _springLength;
          final force = _springConstant * displacement;
          final f = delta / dist * force;
          forces[i] = forces[i] + f;
          forces[j] = forces[j] - f;
        }
      }

      // Central gravity
      for (var i = 0; i < n; i++) {
        final delta = Offset(cx, cy) - positions[i];
        forces[i] = forces[i] + delta * _centralGravity;
      }

      // Apply forces with damping
      for (var i = 0; i < n; i++) {
        velocities[i] = (velocities[i] + forces[i]) * _damping;
        positions[i] = positions[i] + velocities[i];
      }
    }

    // Normalize to fit canvas
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in positions) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final availW = canvasSize.width - _padding * 2;
    final availH = canvasSize.height - _padding * 2;
    final scale = (rangeX > 0 && rangeY > 0)
        ? math.min(availW / rangeX, availH / rangeY)
        : 1.0;

    final normalized = <Offset>[];
    for (final p in positions) {
      normalized.add(
        Offset(
          _padding + (p.dx - minX) * scale,
          _padding + (p.dy - minY) * scale,
        ),
      );
    }

    // Compute radii proportional to file count
    final maxFileCount = graph.nodes
        .map((n) => n.fileCount)
        .reduce(math.max)
        .toDouble();

    return [
      for (var i = 0; i < n; i++)
        PositionedNode(
          node: graph.nodes[i],
          position: normalized[i],
          radius: maxFileCount > 0
              ? _minRadius +
                    (_maxRadius - _minRadius) *
                        (graph.nodes[i].fileCount / maxFileCount)
              : _minRadius,
        ),
    ];
  }
}
