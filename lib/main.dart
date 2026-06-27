import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'data/db_connection.dart';
import 'data/models.dart';
import 'data/workspace_scanner.dart';
import 'ui/draggable_card.dart';
import 'ui/theme.dart';
import 'ui/workspace_picker.dart';
import 'ui/workspace_stats.dart';

const _zoomMin = 0.6;
const _zoomMax = 1.8;
const _zoomStep = 0.1;

const _defaultBackgroundImage = 'assets/images/hero-dawn-temple_seed4830.webp';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ThreadApp());
}

class ThreadApp extends StatelessWidget {
  const ThreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thread',
      debugShowCheckedModeBanner: false,
      theme: threadTheme(),
      home: const _ThreadHome(),
    );
  }
}

class _ThreadHome extends StatefulWidget {
  const _ThreadHome();

  @override
  State<_ThreadHome> createState() => _ThreadHomeState();
}

class _ThreadHomeState extends State<_ThreadHome> {
  double _zoom = 1.0;
  List<WorkspaceInfo> _workspaces = [];
  WorkspaceInfo? _activeWorkspace;
  WorkspaceStats? _stats;
  bool _showStats = false;
  bool _showPicker = false;
  final _db = DbConnection();
  String _backgroundImage = _defaultBackgroundImage;
  late final List<String> _availableBackgrounds;

  @override
  void initState() {
    super.initState();
    _availableBackgrounds = _scanBackgrounds();
    _workspaces = scanWorkspaces();
    if (_workspaces.length == 1) {
      _selectWorkspace(_workspaces.first);
    } else if (_workspaces.isNotEmpty) {
      _showPicker = true;
    }
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  List<String> _scanBackgrounds() {
    final dir = Directory('assets/images');
    if (!dir.existsSync()) return [_defaultBackgroundImage];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => 'assets/images/${f.uri.pathSegments.last}')
        .toList()
      ..sort();
  }

  void _selectWorkspace(WorkspaceInfo ws) {
    _db.open(ws.dbPath);
    setState(() {
      _activeWorkspace = ws;
      _stats = _db.queryStats(ws.name);
      _showStats = true;
      _showPicker = false;
    });
  }

  void _closeStats() {
    setState(() => _showStats = false);
  }

  void _closePicker() {
    setState(() => _showPicker = false);
  }

  void _refresh() {
    if (_activeWorkspace != null) {
      _selectWorkspace(_activeWorkspace!);
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + _zoomStep).clamp(_zoomMin, _zoomMax);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - _zoomStep).clamp(_zoomMin, _zoomMax);
    });
  }

  void _openWorkspacePicker() {
    setState(() {
      _showPicker = true;
    });
  }

  void _showContextMenu(Offset position) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
      PopupMenuItem<String>(
        value: 'workspaces',
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            const Text('Open workspace'),
          ],
        ),
      ),
    );

    if (_availableBackgrounds.length > 1) {
      items.add(const PopupMenuDivider());
      for (final bg in _availableBackgrounds) {
        final name = bg.split('/').last.split('.').first;
        final isActive = bg == _backgroundImage;
        items.add(
          PopupMenuItem<String>(
            value: 'bg:$bg',
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.5),
                ),
                const SizedBox(width: 12),
                Text(name),
              ],
            ),
          ),
        );
      }
    }

    items.add(const PopupMenuDivider());
    items.add(
      PopupMenuItem<String>(
        value: 'refresh',
        child: Row(
          children: [
            Icon(
              Icons.refresh,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            const Text('Refresh'),
          ],
        ),
      ),
    );

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
      if (value == null) return;
      if (value == 'workspaces') {
        _openWorkspacePicker();
      } else if (value.startsWith('bg:')) {
        setState(() => _backgroundImage = value.substring(3));
      } else if (value == 'refresh') {
        _refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = (size.width - 400) / 2;
    final centerY = (size.height - 300) / 2;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal):
            const _ZoomInIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus):
            const _ZoomOutIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            const _RefreshIntent(),
      },
      child: Actions(
        actions: {
          _ZoomInIntent: CallbackAction<_ZoomInIntent>(
            onInvoke: (_) => _zoomIn(),
          ),
          _ZoomOutIntent: CallbackAction<_ZoomOutIntent>(
            onInvoke: (_) => _zoomOut(),
          ),
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (_) => _refresh(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapUp: (details) {
                _showContextMenu(details.globalPosition);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_backgroundImage, fit: BoxFit.cover),
                  MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(_zoom)),
                    child: Stack(
                      children: [
                        if (_showStats && _stats != null)
                          DraggableCard(
                            key: ValueKey('stats-${_activeWorkspace!.name}'),
                            initialOffset: Offset(centerX, centerY),
                            onClose: _closeStats,
                            child: WorkspaceStatsView(stats: _stats!),
                          ),
                        if (_showPicker && _workspaces.isNotEmpty)
                          DraggableCard(
                            key: const ValueKey('picker'),
                            initialOffset: Offset(centerX, centerY),
                            onClose: _closePicker,
                            child: WorkspacePicker(
                              workspaces: _workspaces,
                              onSelect: _selectWorkspace,
                            ),
                          ),
                        if (_workspaces.isEmpty)
                          Center(
                            child: Text(
                              'No sutra workspaces found in ~/.sutra/',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomInIntent extends Intent {
  const _ZoomInIntent();
}

class _ZoomOutIntent extends Intent {
  const _ZoomOutIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}
