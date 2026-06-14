# nivo_plugins

First-party CGM plugins for [Nivo](https://github.com/manuel-g-ferreira/nivo).

Plugins are standalone Dart executables that communicate with the host app via [JSON line protocol v1](docs/PLUGIN-PROTOCOL-V1.md).

## Plugins

| Plugin | ID | Description |
|--------|-----|-------------|
| `plugins/MockCGM/` | `mockcgm` | Synthetic CGM for development and tests |
| `plugins/LibreLink/` | `librelink` | LibreLink Up integration |
| `plugins/Nightscout/` | `nightscout` | Nightscout integration |

## Local setup

Clone next to the app repo:

```text
Gluco/
├── nivo/
└── nivo_plugins/   ← this repo
```

## Build a plugin

```bash
dart pub get
dart run tool/glucose_plugin.dart build plugins/MockCGM
```

Produces `plugins/<Name>/bin/<platform-id>/<binary>` and optionally `dist/<id>.nivoplugin`.

Skip packaging during CI-style builds:

```bash
dart run tool/glucose_plugin.dart build --no-package plugins/MockCGM
```

## Install into Nivo

Build a `.nivoplugin` package, then drag it into **Settings → Plugins** in the app, or use the file picker there.

Example output path:

```text
plugins/MockCGM/dist/mockcgm.nivoplugin
```

## Local CI

See [docs/ci/README.md](docs/ci/README.md) — run the same `dart format`, `dart test`, and plugin build steps as the PR workflow.

## Docs

See [`docs/`](docs/) for authoring guides, vendor API notes, and the plugin protocol contract.
