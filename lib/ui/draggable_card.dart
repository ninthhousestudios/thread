import 'package:flutter/material.dart';
import 'theme.dart';

class DraggableCard extends StatefulWidget {
  final Offset initialOffset;
  final double maxWidth;
  final Widget child;

  const DraggableCard({
    super.key,
    required this.initialOffset,
    this.maxWidth = 460,
    required this.child,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> {
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          decoration: cardDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
