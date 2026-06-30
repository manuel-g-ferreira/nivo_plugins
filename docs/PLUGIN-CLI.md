# Plugin authoring CLI

Use **`dart run tool/glucose_plugin.dart`** from the repo root. It scaffolds new plugins, compiles binaries, and writes **`dist/<id>.nivo`**.

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
- `pubspec.yaml` — Dart package with `nivo_plugins` path dependency
- `bin/<slug>_plugin.dart` — `runPluginStdio` entry
- `lib/protocol_dispatch.dart` — stub protocol handlers (replace with vendor API)

Optional: `--dir CustomFolder` (default: PascalCase from display name), `--force` to overwrite.

### `build`

```bash
dart run tool/glucose_plugin.dart build plugins/MyCgm
```

Runs `dart pub get`, `dart compile exe` for the current OS, then writes `plugins/MyCgm/dist/mycgm.nivo`.

Use `--no-package` to compile only (CI matrix builds).

### `package`

If you already compiled `bin/<platform-id>/` binaries (e.g. from CI), only package:

```bash
dart run tool/glucose_plugin.dart package plugins/MyCgm
```

## Install in Nivo

End users: drag **`dist/<id>.nivo`** into **Settings → Plugins** on any OS.

## Related

- [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md)
- [PLUGIN-MANIFEST.md](PLUGIN-MANIFEST.md)
- [AUTHORING.md](AUTHORING.md)
