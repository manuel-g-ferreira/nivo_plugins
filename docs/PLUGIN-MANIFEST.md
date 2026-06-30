# plugin.json — plugin manifest (v1)

Every installable plugin includes a **`plugin.json`** next to its binaries. The host reads this file **without** starting the plugin (except `getPluginInfo` probe uses the resolved executable).

## Required fields

| Field | Type | Description |
|-------|------|-------------|
| `identifier` | string | Unique slug, e.g. `librelink` (package folder: `librelink.nivo`) |
| `displayName` | string | Shown in Settings → Plugins |
| `version` | string | Semver, e.g. `1.0.0` |
| `apiVersion` | string | Must be `"1"` for current Nivo |
| `entry` | object | Map of platform id → relative path to executable |

## Optional fields

| Field | Type | Description |
|-------|------|-------------|
| `author` | string | Author or org name |
| `homepage` | string | URL for docs/support |
| `minHostVersion` | string | Nivo semver if needed later |

## Entry rules (locked — Option A)

| Rule | Detail |
|------|--------|
| **Must** | `entry` points to a **real executable file** (ELF, Mach-O, PE) |
| **Must not** | `.py`, `.js`, `.ts`, `.sh`, `.bat`, `.jar` as the resolved entry |
| **Must not** | Wrapper scripts that invoke `python`, `node`, `java`, etc. |
| Per platform | At least the platforms you support; missing key → plugin unavailable on that OS |

Authors bundle interpreters **into** the executable (PyInstaller, pkg, jpackage, etc.). See [AUTHORING.md](AUTHORING.md).

## Platform ids (`entry` keys)

| id | OS / arch |
|----|-----------|
| `darwin-arm64` | macOS Apple Silicon |
| `darwin-x64` | macOS Intel |
| `windows-x64` | Windows 64-bit |
| `linux-x64` | Linux 64-bit |

Host picks the key matching `Platform.operatingSystem` + architecture. If missing → plugin unavailable on this platform (catalog shows warning).

## Example

```json
{
  "identifier": "com.example.cgm",
  "displayName": "Example CGM",
  "version": "1.0.0",
  "apiVersion": "1",
  "author": "Example Author",
  "entry": {
    "darwin-arm64": "bin/darwin-arm64/cgm-plugin",
    "darwin-x64": "bin/darwin-x64/cgm-plugin",
    "windows-x64": "bin/windows-x64/cgm-plugin.exe",
    "linux-x64": "bin/linux-x64/cgm-plugin"
  }
}
```

## Bundle layout

```text
com.example.cgm/
  plugin.json
  bin/
    darwin-arm64/cgm-plugin
    darwin-x64/cgm-plugin
    windows-x64/cgm-plugin.exe
    linux-x64/cgm-plugin
```

On macOS the same folder may be named `Example CGM.nivo` (directory bundle).

## Validation (host)

1. `plugin.json` exists and parses
2. `apiVersion === "1"`
3. Resolved `entry` path exists and is executable (Unix: `chmod +x` on install)
4. Spawn with `getPluginInfo`; response `identifier` matches manifest (recommended)

## Relationship to `getPluginInfo`

| Source | Used for |
|--------|----------|
| `plugin.json` | Discovery before spawn; platform entry; install UI |
| `getPluginInfo` response | Capabilities, live version, `requiresLogin`; cached in `plugin-metadata-cache.json` |

If manifest and `getPluginInfo.identifier` differ, host prefers **getPluginInfo** and logs warning.
