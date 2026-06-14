# CGM plugins — documentation

## MVP workflow

1. Copy [API-ANALYSIS-TEMPLATE.md](API-ANALYSIS-TEMPLATE.md) → `librelink-api-analysis.md` (or vendor name).
2. Capture redacted API responses from vendor or dev proxy.
3. Agree MVP fetch proposal (single call vs two calls; no host merge v1).
4. Implement plugin normalization only if analysis shows need.
5. Implement host fetch as assign-only ([ADR 004](../adr/004-mvp-analyze-apis-first.md)).

## Architecture decisions

- [PLUGIN-CLI.md](PLUGIN-CLI.md) — `dart run tool/glucose_plugin.dart` (create, build, package)
- [MULTI-VENDOR-PLUGIN-DESIGN.md](MULTI-VENDOR-PLUGIN-DESIGN.md) — Dexcom, Nightscout, LibreLink: one plugin per vendor, shared host contract
- [ADR 002 — No SQLite first iteration](../adr/002-no-sqlite-first-iteration.md)
- [ADR 003 — No host merge](../adr/003-plugin-canonical-history-no-merge.md)
- [ADR 004 — MVP, analyze first](../adr/004-mvp-analyze-apis-first.md)

## Authoring (third-party)

Anyone can write a plugin by respecting the connection points only:

| Doc | Purpose |
|-----|---------|
| [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) | Five commands — **the contract** |
| [PLUGIN-MANIFEST.md](PLUGIN-MANIFEST.md) | `plugin.json` + per-OS binaries |
| [AUTHORING.md](AUTHORING.md) | Guide for plugin developers |
| [ADR 029](../adr/029-plugin-ecosystem.md) | Locked: language-agnostic, native binaries |

**Distribution (locked):** **Option A for all languages** — frozen/native `bin/{platform-id}/executable` only; no user-installed Python/Node/Java. See [ADR 029](../adr/029-plugin-ecosystem.md).

## Plugin artifacts

| Plugin | Analysis | Design | Status |
|--------|------------|--------|--------|
| **Protocol v1** | — | [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) | Locked for MVP |
| Mock CGM | [mock-api-analysis.md](mock-api-analysis.md) | Same protocol bodies | Ready to implement |
| LibreLink Up | [librelink-api-analysis.md](librelink-api-analysis.md) | [librelink-plugin-considerations.md](librelink-plugin-considerations.md) | Implemented in `plugins/LibreLink` |
| Nightscout | [nightscout-api-analysis.md](nightscout-api-analysis.md) | [MULTI-VENDOR-PLUGIN-DESIGN.md](MULTI-VENDOR-PLUGIN-DESIGN.md) | Implemented in `plugins/Nightscout` |
| Dexcom | *(planned)* | [MULTI-VENDOR-PLUGIN-DESIGN.md](MULTI-VENDOR-PLUGIN-DESIGN.md#example-dexcom-sketch) | Separate plugin `com.nivo.dexcom` |

## External references (LibreLink Up)

- [DRFR0ST/libre-link-unofficial-api](https://github.com/DRFR0ST/libre-link-unofficial-api)
- [DiaKEM/libre-link-up-api-client](https://github.com/DiaKEM/libre-link-up-api-client)
- [khskekec API gist](https://gist.github.com/khskekec/6c13ba01b10d3018d816706a32ae8ab2)
