import 'package:flutter/material.dart';
import 'theme.dart';

class DraggableCard extends StatefulWidget {
  final Offset initialOffset;
  final double maxWidth;
  final VoidCallback? onClose;
  final Widget child;

  const DraggableCard({
    super.key,
    required this.initialOffset,
    this.maxWidth = 460,
    this.onClose,
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

  void _showCardMenu(Offset position) {
    final items = <PopupMenuEntry<String>>[];

    if (widget.onClose != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'close',
          child: Row(
            children: [
              Icon(
                Icons.close,
                size: 20,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              const Text('Close'),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    ).then((value) {
      if (value == 'close') widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          _showCardMenu(details.globalPosition);
        },
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
