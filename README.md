# nivo-plugins

First-party CGM plugins for [Nivo](https://github.com/manuel-g-ferreira/nivo).

Plugins are standalone Dart executables that communicate with the host app via [JSON line protocol v1](docs/PLUGIN-PROTOCOL-V1.md).

## Plugins

| Plugin | ID | Description |
|--------|-----|-------------|
| `plugins/MockCGM/` | `mockcgm` | Synthetic CGM for development and tests |
| `plugins/LibreLink/` | `librelink` | LibreLink Up integration |
| `plugins/Nightscout/` | `nightscout` | Nightscout integration |
| `plugins/DexcomShare/` | `dexcomshare` | Dexcom Share integration |

## Local setup

Clone next to the app repo:

```text
Gluco/
├── nivo/
└── nivo-plugins/   ← this repo (clone name; Dart package inside is still `nivo_plugins`)
```

```bash
dart pub get
```

## Build a plugin

```bash
dart run tool/glucose_plugin.dart build plugins/MockCGM
```

Produces `plugins/<Name>/bin/<platform-id>/<binary>` and `dist/<id>.nivo`.

Skip packaging during CI-style builds:

```bash
dart run tool/glucose_plugin.dart build --no-package plugins/MockCGM
```

## Install into Nivo

Drag **`dist/<id>.nivo`** into **Settings → Plugins** in the app, or use the file picker there.

## CI & releases

See [docs/ci/README.md](docs/ci/README.md).

Tagged releases on **`nivo-plugins`** (this repo) build the catalog under **`catalog/`** and publish to **[`nivo-plugin-catalog`](https://github.com/manuel-g-ferreira/nivo-plugin-catalog)**:

- `catalog.json` — metadata + download URLs
- `dist/*.nivo` — installable packages for Nivo
- GitHub Releases — same `.nivo` files for browser download

Users add the catalog manually in **Settings → Plugins → Add source**:

```text
https://raw.githubusercontent.com/manuel-g-ferreira/nivo-plugin-catalog/main/catalog.json
```

## Docs

See [docs/README.md](docs/README.md) for the protocol contract, authoring guide, and vendor API notes.
