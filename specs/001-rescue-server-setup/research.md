# Research: Rescue Server Setup

## Unknowns & Decisions

### 1. Robust IP Detection
**Context**: The spec requires prioritizing `en0` then `en1`.
**Research**: `ipconfig getifaddr en0` is standard on macOS.
- **Decision**: Use `ipconfig getifaddr` with a fallback chain.
- **Rationale**: Built-in, reliable on macOS. `ifconfig` is harder to parse reliably.
- **Alternatives**: Python `socket` module (requires launching python interpreter during shell script execution - slower).

### 2. Git Initialization
**Context**: Must initialize repo and commit.
**Research**: Standard git commands: `git init`, `git add .`, `git commit -m`.
- **Decision**: Execute standard git commands after directory creation. Check for `git` presence first.
- **Rationale**: Simple, universal.

### 3. Interactive Prompts
**Context**: Need to ask "Start server now?".
**Research**: `read -p "Prompt" -n 1 -r` allows reading a single character without enter.
- **Decision**: Bash `read` command.
- **Rationale**: Native to shell, no dependencies.

### 4. Permission Management
**Context**: Self-chmod.
**Research**: `chmod +x "$0"` allows a script to make itself executable.
- **Decision**: Add this line near the top of the script.
- **Rationale**: Ensures re-usability.

## Conclusion
Typical shell script patterns are sufficient. No external research needed.
