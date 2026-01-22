# Data Model: Rescue Server

## Entities

### Rescue Site (Filesystem)
The root entity managed by the setup script.
- **Path**: `~/Desktop/rescue-site`
- **Owner**: Current User
- **Permissions**: Read/Write (Host), Read-Only (Client/HTTP)

### Subdirectories
- `scripts/`: Diagnostic tools (Shell/Batch).
- `manuals/`: PDFs/Text.
- `drivers/`: Binary installers.
- `audit_logs/`: Text logs of operations.
- `.git/`: Version control metadata.

### Dashboard (HTML)
The visual representation of the entities.
- **index.html**: Static entry point.
- **structure**: Unordered lists (`<ul>`) mapping to subdirectories.

## Persistence
- **State**: Filesystem state.
- **History**: Git repository constraints (Initial commit).
- **Logs**: `audit_logs/server_audit.log` (Append-only).
