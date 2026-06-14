# Writing a Nivo CGM plugin

Anyone can ship a plugin if it respects the **connection points** — no approval from Nivo required.

## Checklist

1. Implement [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) (five commands, line JSON).
2. Add [PLUGIN-MANIFEST.md](PLUGIN-MANIFEST.md) (`plugin.json` + `bin/` per platform).
3. Build a **native executable per OS/CPU** (recommended: Go or Rust).
4. Test: pipe one JSON line in → one JSON line out.
5. Document network endpoints and privacy for users.

## Connection points (only integration surface)

```
stdin  ← host writes one JSON command per line
stdout → plugin writes one JSON response per line
stderr → logs only (ignored by host)
```

No shared library, no Flutter plugin, no HTTP server exposed to the host.

## Distribution rule (all languages — Option A)

**Every published plugin ships frozen/native executables in `bin/`**. Users never install Python, Node, Java, etc.

| You know… | Build per OS → put in `bin/` |
|-----------|------------------------------|
| **Python** | [PyInstaller / Nuitka](#python) |
| **Node / TypeScript** | `pkg`, `nexe`, or `bun build --compile` |
| **Go** | `GOOS/GOARCH go build` |
| **Rust** | `cargo build --target …` |
| **Dart** | `dart compile exe` |
| **Java** | `jpackage` / GraalVM native-image |
| **C#** | `dotnet publish -r … --self-contained` |

Dev on your laptop: run interpreter directly. **Release:** only the four binaries + `plugin.json`.

## Python

Nivo does **not** run Python inside the app. Your plugin is still a **separate program** that reads **one JSON line from stdin** and writes **one JSON line to stdout**. That is a few lines in Python.

### Minimal loop (protocol v1)

```python
#!/usr/bin/env python3
import json
import sys

def handle(cmd: dict) -> dict:
    command = cmd.get("command")
    if command == "getPluginInfo":
        return {
            "success": True,
            "identifier": "com.you.myplugin",
            "displayName": "My CGM",
            "version": "1.0.0",
            "author": "You",
            "requiresLogin": True,
            "iconName": "default",
            "capabilities": {
                "supportsMultipleDataSources": False,
                "supportsHistory": True,
                "maxHistoryHours": 24,
                "supportsSpecialValues": False,
                "requiresRegionSelection": False,
                "apiVersion": "1",
            },
        }
    if command == "authenticate":
        # Call vendor API with cmd["username"], cmd["password"]; store token in memory
        return {"success": True, "authToken": "…", "userId": "…"}
    if command == "getDataSources":
        return {"success": True, "dataSources": [{"id": "1", "name": "Sensor"}]}
    if command == "getCurrentReading":
        return {
            "success": True,
            "value": 120,
            "trend": "flat",
            "timestamp": "2026-05-30T12:00:00.000Z",
            "specialValue": None,
        }
    if command == "getHistory":
        hours = cmd.get("hours", 3)
        return {"success": True, "readings": []}  # list of same shape as current
    return {"success": False, "error": f"Unknown command: {command}"}

def main() -> None:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            resp = handle(req)
        except Exception as e:
            resp = {"success": False, "error": str(e)}
        sys.stdout.write(json.dumps(resp) + "\n")
        sys.stdout.flush()

if __name__ == "__main__":
    main()
```

Use `requests` or `httpx` inside handlers for vendor HTTP (LibreLink, etc.). Keep tokens in module-level variables after `authenticate`.

### Ship with PyInstaller (or Nuitka)

Build on each target OS (or CI matrix):

```bash
pip install pyinstaller httpx
pyinstaller --onefile --name my-cgm-plugin my_plugin.py
# → dist/my-cgm-plugin (mac/linux) or dist/my-cgm-plugin.exe (windows)
```

Copy into manifest layout:

```text
com.you.myplugin/
  plugin.json
  bin/
    darwin-arm64/my-cgm-plugin
    darwin-x64/my-cgm-plugin
    windows-x64/my-cgm-plugin.exe
    linux-x64/my-cgm-plugin
```

Nivo runs the binary — it does not know it was Python. Alternatives: `cx_Freeze`, `py2app`, **Nuitka**.

### Python checklist

- [ ] One JSON line in, one out (no pretty-printed multi-line JSON)
- [ ] `sys.stdout.flush()` after every response
- [ ] Log debug text to **stderr** only, never stdout
- [ ] HTTPS and credentials stay inside the plugin process
- [ ] **Four frozen binaries** in `bin/` for release (Option A)

## Vendor API inside your process

- Keep HTTP/WebSocket to Abbott, Dexcom, etc. **inside the plugin**.
- Map vendor responses to protocol `value`, `trend`, `timestamp`, `specialValue`.
- Normalize duplicates in the **plugin** (see [librelink-api-analysis.md](librelink-api-analysis.md)).

## Session handling

After `authenticate`, store tokens in plugin memory. Use `authToken`, `userId`, `dataSourceId` from each command to pick the right session.

`options` can carry plugin-specific settings (region, API base URL) set from host `AppSettings.pluginSettings`.

## Capabilities (honest flags)

```json
{
  "supportsMultipleDataSources": true,
  "supportsHistory": true,
  "maxHistoryHours": 24,
  "supportsSpecialValues": false,
  "requiresRegionSelection": true,
  "apiVersion": "1"
}
```

Host uses these for history window and multi-connection UI. Declare sign-in fields (region, credentials, URL) in `getPluginInfo.signIn` — see [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md).

## Install location (end users)

| OS | Plugins directory |
|----|-------------------|
| macOS | `~/Library/Application Support/Nivo/Plugins/` |
| Windows | `%AppData%\Nivo\Plugins\` |
| Linux | `~/.local/share/Nivo/plugins/` |

Ship a **`.nivoplugin`** package (directory bundle, not zip). Build with:

```bash
dart run tool/glucose_plugin.dart build plugins/YourPlugin
```

End users drag the package into **Settings → Plugins** or use **Choose .nivoplugin…**.

## Official references

- [ADR 029 — Plugin ecosystem](../adr/029-plugin-ecosystem.md)
- Mock plugin: [ADR 025](../adr/025-mock-plugin.md)
- LibreLink plugin: [ADR 024](../adr/024-librelink-plugin.md)
