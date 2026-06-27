import 'dart:ui';

import '../data/graph_model.dart';

class PositionedNode {
  final ComponentNode node;
  final Offset position;
  final double radius;

  const PositionedNode({
    required this.node,
    required this.position,
    required this.radius,
  });
}

abstract class LayoutEngine {
  List<PositionedNode> layout(ComponentGraph graph, Size canvasSize);
}
