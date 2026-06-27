import 'package:flutter/material.dart';
import '../data/models.dart';

class WorkspacePicker extends StatelessWidget {
  final List<WorkspaceInfo> workspaces;
  final void Function(WorkspaceInfo) onSelect;

  const WorkspacePicker({
    super.key,
    required this.workspaces,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select workspace',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${workspaces.length} sutra-indexed projects found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          for (final ws in workspaces)
            _WorkspaceRow(workspace: ws, onTap: () => onSelect(ws)),
        ],
      ),
    );
  }
}

class _WorkspaceRow extends StatefulWidget {
  final WorkspaceInfo workspace;
  final VoidCallback onTap;

  const _WorkspaceRow({required this.workspace, required this.onTap});

  @override
  State<_WorkspaceRow> createState() => _WorkspaceRowState();
}

class _WorkspaceRowState extends State<_WorkspaceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.workspace.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
