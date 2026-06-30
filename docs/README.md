# Documentation

## Contract (read first)

| Doc | Purpose |
|-----|---------|
| [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) | stdin/stdout JSON-line protocol |
| [PLUGIN-MANIFEST.md](PLUGIN-MANIFEST.md) | `plugin.json` + per-OS binaries |
| [AUTHORING.md](AUTHORING.md) | Guide for plugin developers |
| [PLUGIN-CLI.md](PLUGIN-CLI.md) | `dart run tool/glucose_plugin.dart` |
| [ci/README.md](ci/README.md) | CI and release workflows |

## Plugins

| Plugin | ID | Code | Vendor API notes |
|--------|-----|------|------------------|
| Mock CGM | `mockcgm` | `plugins/MockCGM/` | — |
| LibreLink Up | `librelink` | `plugins/LibreLink/` | [librelink-api-analysis.md](librelink-api-analysis.md) |
| Nightscout | `nightscout` | `plugins/Nightscout/` | [nightscout-api-analysis.md](nightscout-api-analysis.md) |
| Dexcom Share | `dexcomshare` | `plugins/DexcomShare/` | [dexcomshare-api-analysis.md](dexcomshare-api-analysis.md) |

Packages install as **`.nivo`** directory bundles. Build with `dart run tool/glucose_plugin.dart build plugins/<Name>`.
