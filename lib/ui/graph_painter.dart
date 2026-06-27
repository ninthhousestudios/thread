import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/graph_model.dart';
import '../layout/layout_engine.dart';

const _healthGreen = Color(0xFF59A14F);
const _healthYellow = Color(0xFFEDC948);
const _healthRed = Color(0xFFE15759);

Color healthColor(double score) {
  if (score >= 7.5) {
    final t = (score - 7.5) / 2.5;
    return Color.lerp(_healthYellow, _healthGreen, t)!;
  } else {
    final t = (score - 1.0) / 6.5;
    return Color.lerp(_healthRed, _healthYellow, t)!;
  }
}

class GraphPainter extends CustomPainter {
  final List<PositionedNode> nodes;
  final List<ComponentEdge> edges;
  final String? hoveredNodeId;

  GraphPainter({required this.nodes, required this.edges, this.hoveredNodeId});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final nodeMap = <String, PositionedNode>{};
    for (final n in nodes) {
      nodeMap[n.node.id] = n;
    }

    _paintEdges(canvas, nodeMap);
    _paintNodes(canvas);
    _paintLabels(canvas);
  }

  void _paintEdges(Canvas canvas, Map<String, PositionedNode> nodeMap) {
    if (edges.isEmpty) return;

    final maxWeight = edges.map((e) => e.weight).reduce(math.max).toDouble();
    final paint = Paint()..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src == null || tgt == null) continue;

      final t = maxWeight > 0 ? edge.weight / maxWeight : 0.0;
      paint
        ..strokeWidth = 1.0 + 3.0 * t
        ..color = Colors.white.withValues(alpha: 0.12 + 0.18 * t);

      final delta = tgt.position - src.position;
      final dist = delta.distance;
      if (dist < 1.0) continue;
      final dir = delta / dist;

      final from = src.position + dir * src.radius;
      final to = tgt.position - dir * tgt.radius;
      canvas.drawLine(from, to, paint);

      // Arrowhead
      final arrowSize = 6.0 + 2.0 * t;
      final perp = Offset(-dir.dy, dir.dx);
      final p1 = to - dir * arrowSize + perp * arrowSize * 0.4;
      final p2 = to - dir * arrowSize - perp * arrowSize * 0.4;
      final arrowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = paint.color;
      canvas.drawPath(
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close(),
        arrowPaint,
      );
    }
  }

  void _paintNodes(Canvas canvas) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final n in nodes) {
      final color = healthColor(n.node.healthScore);
      fillPaint.color = color;

      final isHovered = n.node.id == hoveredNodeId;
      borderPaint
        ..color = isHovered ? Colors.white : color.withValues(alpha: 0.6)
        ..strokeWidth = isHovered ? 3.0 : 1.5;

      canvas.drawCircle(n.position, n.radius, fillPaint);
      canvas.drawCircle(n.position, n.radius, borderPaint);
    }
  }

  void _paintLabels(Canvas canvas) {
    final maxRadius = nodes.map((n) => n.radius).reduce(math.max);
    final labelThreshold = maxRadius * 0.15;

    for (final n in nodes) {
      if (n.radius < labelThreshold && n.node.id != hoveredNodeId) continue;

      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.center,
                maxLines: 1,
                ellipsis: '…',
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            )
            ..addText(n.node.name);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: n.radius * 4));

      canvas.drawParagraph(
        paragraph,
        Offset(
          n.position.dx - paragraph.maxIntrinsicWidth / 2,
          n.position.dy + n.radius + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) =>
      nodes != oldDelegate.nodes ||
      edges != oldDelegate.edges ||
      hoveredNodeId != oldDelegate.hoveredNodeId;
}
