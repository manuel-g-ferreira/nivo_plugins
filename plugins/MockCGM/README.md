# Mock CGM plugin

Reference plugin (`mockcgm`) for dev and CI. Speaks [PLUGIN-PROTOCOL-V1](../../docs/plugins/PLUGIN-PROTOCOL-V1.md).

## Build

```bash
dart run tool/glucose_plugin.dart build plugins/MockCGM
```

Binary: `plugins/MockCGM/bin/<platform-id>/mock-cgm`

## Install (same as any plugin)

```bash
dart run tool/glucose_plugin.dart install plugins/MockCGM/dist/mockcgm.nivoplugin
```

Or drag `dist/mockcgm.nivoplugin` into **Settings → Plugins**.

Then select **Mock CGM** under **Data Source** and sign in (any credentials work).

## Layout

Same structure as LibreLink and Nightscout:

- `plugin.json` — manifest
- `lib/` — protocol handlers
- `bin/mock_cgm_plugin.dart` — compiled entrypoint
- `bin/<platform-id>/mock-cgm` — built binary (gitignored)
