import 'package:flutter/material.dart';
import '../data/models.dart';

class WorkspaceStatsView extends StatelessWidget {
  final WorkspaceStats stats;

  const WorkspaceStatsView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(label: 'Files', value: stats.fileCount.toString()),
          const SizedBox(height: 8),
          _StatRow(label: 'Symbols', value: stats.symbolCount.toString()),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Last parsed',
            value: _formatLastParsed(stats.lastParsed),
          ),
        ],
      ),
    );
  }

  String _formatLastParsed(DateTime? dt) {
    if (dt == null) return 'unknown';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
