# godot-2d-undirected-metric-graph-editor
A editor capable of displaying and working with undirected metric graphs.

## Controls

### Node Selection

| Action | Control | Description |
|--------|---------|-------------|
| Select Node | Left Mouse Button | Select the hovered node |
| Select Additional Node | Shift+Left Mouse Button | Add the hovered node to selection |
| Select All | A | Select all nodes in the graph |
| Deselect | Ctrl+Left Mouse Button | Deselect hovered node |
| Deselect All | Left Mouse Button into void | Deselect all currently selected nodes |

### Node Management

| Action | Control | Description |
|--------|---------|-------------|
| Add Node | Shift+A | Create a new isolated node |
| Add Fully Connected Node | Ctrl+A | Create a new node connected to all existing nodes |
| Add Connected Node | Alt+A | Create a new node connected to currently selected nodes |
| Remove Nodes | X | Delete selected nodes from the graph |
| Move Node | G | Move last selected node to cursor |
| Print Node Info | I | Display information about selected nodes |
| Hide Node | H | Hide selected nodes (and edges connected to them) |
| Reveal Hidden Nodes | Alt+H | Reveal nodes markes as hidden |
| Toggle Edge Mode | Ctrl+H | Toggle between showing edges of all visible nodes and only showing edges of selected nodes |

### Node Connections

| Action | Control | Description |
|--------|---------|-------------|
| Connect Nodes | C | Create connections between selected nodes |
| Connect to All | Alt+C | Connect selected nodes to all other nodes |
| Disconnect Nodes | D | Remove connections between selected nodes |
| Disconnect from All | Ctrl+D | Remove all connections from selected nodes |

### Navigation

| Action | Control | Description |
|--------|---------|-------------|
| Zoom In | Mouse Wheel Up | Increase graph view magnification |
| Zoom Out | Mouse Wheel Down | Decrease graph view magnification |
| Pan | Middle Mouse Button | Move the graph view |