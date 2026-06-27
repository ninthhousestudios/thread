# Thread

Visual architecture map for sutra-indexed codebases. Reads sutra's SQLite database and renders an interactive force-directed graph of components, their health, and cross-component dependencies.

## What it shows

- **Nodes** = sutra components (Leiden-clustered file groups), sized by file count, colored by health score (green / yellow / red)
- **Edges** = cross-component symbol references, thickness proportional to weight, with directional arrows
- **Tooltips** on hover: component name, health score, file count, line count, connection degree

## Controls

- **Pan**: click and drag the canvas
- **Zoom**: scroll wheel or pinch (0.3x-3x)
- **Refresh**: Ctrl+R or right-click > Refresh (re-reads sutra DB)
- **Workspace**: right-click > Open workspace to switch between sutra-indexed projects
- **Background**: right-click to pick from available wallpapers

## Requirements

- Linux (Flutter desktop)
- Dart SDK >= 3.11.1
- Sutra workspaces in `~/.sutra/` with `index.db` files

## Build and run

```
flutter run -d linux
```
