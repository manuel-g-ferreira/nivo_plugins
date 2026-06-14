# Plugin authoring CLI

Use **`dart run tool/glucose_plugin.dart`** from the repo root. It scaffolds new plugins, compiles binaries, and writes **`dist/<id>.nivoplugin`** — one executable file per platform (not a folder or zip).

## Why a repo CLI?

| Approach | Pros |
|----------|------|
| **In-repo Dart CLI** (chosen) | Same SDK as plugins, no extra install, versioned with protocol v1 |
| Global `glucose_plugin` on PATH | Extra publish/release step; harder to keep in sync |
| IDE-only templates | No build/package automation |

## Commands

### `create`

```bash
dart run tool/glucose_plugin.dart create \
  --id mycgm \
  --name "My CGM" \
  --author "Your Name"
```

Creates `plugins/MyCgm/` with:

- `plugin.json` — manifest and platform `entry` map
- `pubspec.yaml` — Dart package for the plugin
- `bin/<slug>_plugin.dart` — stdin/stdout entry
- `lib/protocol_dispatch.dart` — stub protocol handlers (replace with vendor API)
- `lib/plugin_config.dart` — identifier constants

Optional: `--dir CustomFolder` (default: PascalCase from display name), `--force` to overwrite.

### `build`

```bash
dart run tool/glucose_plugin.dart build plugins/MyCgm
```

Runs `dart pub get`, `dart compile exe` for the current OS, then writes:

`plugins/MyCgm/dist/mycgm.nivoplugin`

### `package`

If you already compiled `bin/<platform-id>/` binaries (e.g. from CI), only package:

```bash
dart run tool/glucose_plugin.dart package plugins/MyCgm
```

## Install in Nivo

End users: drag **`dist/<id>.nivoplugin`** into **Settings → Plugins** on any OS. No terminal required.

Developers: `dart run tool/glucose_plugin.dart build plugins/<Name>` produces `dist/<id>.nivoplugin`.

## Legacy per-plugin scripts

Still supported:

- `dart run tool/build_nightscout_plugin.dart`

Prefer `glucose_plugin.dart build plugins/<Name>` for all plugins (including MockCGM).

## Related

- [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md)
- [PLUGIN-MANIFEST.md](PLUGIN-MANIFEST.md)
- [AUTHORING.md](AUTHORING.md)
