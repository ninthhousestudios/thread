import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/graph_model.dart';
import '../layout/layout_engine.dart';
import 'graph_painter.dart';
import 'theme.dart';

class GraphCard extends StatefulWidget {
  final ComponentGraph graph;
  final List<PositionedNode> layout;

  const GraphCard({super.key, required this.graph, required this.layout});

  @override
  State<GraphCard> createState() => _GraphCardState();
}

class _GraphCardState extends State<GraphCard> {
  String? _hoveredNodeId;
  Offset? _hoverPosition;
  final _transformController = TransformationController();
  bool _didCenter = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _centerOnGraph(Size viewportSize, Size canvasSize) {
    if (_didCenter) return;
    _didCenter = true;
    final dx = (canvasSize.width - viewportSize.width) / 2;
    final dy = (canvasSize.height - viewportSize.height) / 2;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(-dx, -dy, 0, 1);
  }

  void _handleHover(PointerHoverEvent event) {
    final matrix = _transformController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final scenePoint = MatrixUtils.transformPoint(
      inverseMatrix,
      event.localPosition,
    );

    String? hit;
    for (final n in widget.layout) {
      if ((scenePoint - n.position).distance <= n.radius) {
        hit = n.node.id;
        break;
      }
    }
    if (hit != _hoveredNodeId) {
      setState(() {
        _hoveredNodeId = hit;
        _hoverPosition = hit != null ? event.localPosition : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.layout.isEmpty) {
      return Center(
        child: Text(
          'No components found',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Canvas = 3x viewport so there's room to pan in all directions
        final canvasSize = Size(
          viewportSize.width * 3,
          viewportSize.height * 3,
        );

        // Compute offset to center the laid-out graph within the canvas
        var minX = double.infinity, minY = double.infinity;
        var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
        for (final n in widget.layout) {
          minX = minX < n.position.dx - n.radius
              ? minX
              : n.position.dx - n.radius;
          minY = minY < n.position.dy - n.radius
              ? minY
              : n.position.dy - n.radius;
          maxX = maxX > n.position.dx + n.radius
              ? maxX
              : n.position.dx + n.radius;
          maxY = maxY > n.position.dy + n.radius
              ? maxY
              : n.position.dy + n.radius;
        }
        final graphW = maxX - minX;
        final graphH = maxY - minY;
        final offsetX = (canvasSize.width - graphW) / 2 - minX;
        final offsetY = (canvasSize.height - graphH) / 2 - minY;
        final centerOffset = Offset(offsetX, offsetY);

        final centeredNodes = [
          for (final n in widget.layout)
            PositionedNode(
              node: n.node,
              position: n.position + centerOffset,
              radius: n.radius,
            ),
        ];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerOnGraph(viewportSize, canvasSize);
        });

        return MouseRegion(
          onHover: _handleHover,
          onExit: (_) => setState(() {
            _hoveredNodeId = null;
            _hoverPosition = null;
          }),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.3,
                maxScale: 3.0,
                constrained: false,
                child: CustomPaint(
                  painter: GraphPainter(
                    nodes: centeredNodes,
                    edges: widget.graph.edges,
                    hoveredNodeId: _hoveredNodeId,
                  ),
                  size: canvasSize,
                ),
              ),
              if (_hoveredNodeId != null && _hoverPosition != null)
                _buildTooltip(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip() {
    final node = widget.layout
        .firstWhere((n) => n.node.id == _hoveredNodeId)
        .node;

    final degree = widget.graph.edges
        .where((e) => e.sourceId == node.id || e.targetId == node.id)
        .length;

    return Positioned(
      left: _hoverPosition!.dx + 16,
      top: _hoverPosition!.dy - 10,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              _tooltipRow(
                'Health',
                '${node.healthScore.toStringAsFixed(1)} / 10',
                color: healthColor(node.healthScore),
              ),
              _tooltipRow('Files', '${node.fileCount}'),
              _tooltipRow('Lines', _formatNumber(node.lineCount)),
              _tooltipRow('Connections', '$degree'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tooltipRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
