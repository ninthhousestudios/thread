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

  void _handleHover(PointerHoverEvent event, Offset canvasOffset) {
    final local = event.localPosition;
    String? hit;
    for (final n in widget.layout) {
      final adjusted = n.position + canvasOffset;
      if ((local - adjusted).distance <= n.radius) {
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

    // Compute canvas bounds from laid-out nodes
    var maxX = 0.0, maxY = 0.0;
    for (final n in widget.layout) {
      final right = n.position.dx + n.radius + 60;
      final bottom = n.position.dy + n.radius + 40;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }
    final canvasSize = Size(maxX, maxY);

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.3,
      maxScale: 3.0,
      constrained: false,
      child: MouseRegion(
        onHover: (event) => _handleHover(event, Offset.zero),
        onExit: (_) => setState(() {
          _hoveredNodeId = null;
          _hoverPosition = null;
        }),
        child: Stack(
          children: [
            CustomPaint(
              painter: GraphPainter(
                nodes: widget.layout,
                edges: widget.graph.edges,
                hoveredNodeId: _hoveredNodeId,
              ),
              size: canvasSize,
            ),
            if (_hoveredNodeId != null && _hoverPosition != null)
              _buildTooltip(),
          ],
        ),
      ),
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
