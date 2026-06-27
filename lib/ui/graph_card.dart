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
  OverlayEntry? _tooltipEntry;
  final _transformController = TransformationController();
  final _canvasKey = GlobalKey();
  bool _didCenter = false;
  List<PositionedNode> _centeredNodes = [];

  @override
  void dispose() {
    _removeTooltip();
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
    // localPosition is in canvas space (MouseRegion is inside InteractiveViewer)
    final canvasPoint = event.localPosition;

    String? hit;
    PositionedNode? hitNode;
    for (final n in _centeredNodes) {
      if ((canvasPoint - n.position).distance <= n.radius) {
        hit = n.node.id;
        hitNode = n;
        break;
      }
    }

    if (hit != _hoveredNodeId) {
      _hoveredNodeId = hit;
      _removeTooltip();
      if (hit != null && hitNode != null) {
        _showTooltip(event.position, hitNode.node);
      }
      setState(() {});
    }
  }

  void _showTooltip(Offset screenPosition, ComponentNode node) {
    final degree = widget.graph.edges
        .where((e) => e.sourceId == node.id || e.targetId == node.id)
        .length;

    _tooltipEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: screenPosition.dx + 16,
        top: screenPosition.dy - 10,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
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
        ),
      ),
    );
    Overlay.of(context).insert(_tooltipEntry!);
  }

  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry?.dispose();
    _tooltipEntry = null;
  }

  void _handleExit(PointerExitEvent _) {
    _hoveredNodeId = null;
    _removeTooltip();
    setState(() {});
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

        final canvasSize = Size(
          viewportSize.width * 3,
          viewportSize.height * 3,
        );

        // Center the graph within the oversized canvas
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

        _centeredNodes = [
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

        return InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 3.0,
          constrained: false,
          child: MouseRegion(
            key: _canvasKey,
            onHover: _handleHover,
            onExit: _handleExit,
            child: CustomPaint(
              painter: GraphPainter(
                nodes: _centeredNodes,
                edges: widget.graph.edges,
                hoveredNodeId: _hoveredNodeId,
              ),
              size: canvasSize,
            ),
          ),
        );
      },
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
