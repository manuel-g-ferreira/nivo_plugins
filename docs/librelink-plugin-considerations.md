# LibreLink Up plugin — design considerations

**Identifier:** `librelink`  
**Analysis:** [librelink-api-analysis.md](librelink-api-analysis.md)  
**Protocol:** [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md)  
**MVP:** [ADR 004](../adr/004-mvp-analyze-apis-first.md)

---

## Role

Out-of-process plugin (Node, Dart, or Go — TBD at implementation). Translates LibreLink Up HTTP API → Nivo JSON line protocol. Host never calls Abbott directly.

---

## Why one HTTP call per fetch

LibreLink exposes **current + series** in a single graph response. DiaKEM and DRFR0ST both use:

`GET /llu/connections/{patientId}/graph` → `{ connection, graphData }`

| Host command | Source (no host merge) |
|--------------|------------------------|
| `getCurrentReading` | `connection.glucoseMeasurement` (fallback `glucoseItem`) |
| `getHistory` | `graphData` filtered to `hours`, sorted ascending |

Plugin may cache the last graph response for the active `dataSourceId` for one fetch cycle (both commands in same host `fetchConnection`).

---

## Session / `options` shape

Persist in plugin process after `authenticate`:

| Key | Source |
|-----|--------|
| `authToken` | `data.authTicket.token` |
| `userId` | `data.user.id` (follower account — used for `Account-Id` SHA-256) |
| `options.apiBaseUrl` | Regional `lslApi` after redirect |
| `options.clientVersion` | e.g. `4.16.0` — from settings or default |
| `options.accountIdHash` | SHA-256(`user.id`) — precomputed for headers |
| `dataSourceId` | `patientId` from connections |

`requiresRegionSelection: true` in capabilities — host stores `pluginSettings.region` if login redirects before credentials work.

---

## Command mapping

### `authenticate`

1. `POST {apiBaseUrl}/llu/auth/login` with email/password.
2. If redirect → `GET .../llu/config/country?country=DE` → set `apiBaseUrl` from `regionalMap[region].lslApi` → retry login.
3. If `status === 2` → `{ success: false, error: "Invalid credentials" }`.
4. If `status === 4` → surface step required (non-MVP: fail with clear message).
5. Success → return `authToken`, `userId`, optional `defaultDataSourceId` from first connection prefetch.

### `getDataSources`

1. `GET /llu/connections` with auth headers.
2. Map each `data[]` → `{ id: patientId, name: firstName + " " + lastName }`.
3. `supportsMultipleDataSources: data.length > 1`.

### `getCurrentReading` / `getHistory`

1. Ensure graph loaded for `dataSourceId` (HTTP if cache miss/stale).
2. **Current:** map `GlucoseItem` → protocol reading (see below).
3. **History:** map each `graphData` item, filter `timestamp >= now - hours`, sort asc.

Do **not** implement host-side merge with prior chart window ([ADR 003](../adr/003-plugin-canonical-history-no-merge.md)).

---

## Raw → protocol field mapping

| Protocol | LibreLink `GlucoseItem` |
|----------|-------------------------|
| `value` | `ValueInMgPerDl` (round int) |
| `timestamp` | Prefer `FactoryTimestamp` parsed as UTC (DiaKEM); fallback `Timestamp` |
| `trend` | `TrendArrow` → protocol string (see analysis table) |
| `specialValue` | null for MVP (LO/HI not in standard graph items) |
| `isHigh` / `isLow` | Use API flags; optional recalc from connection `targetLow`/`targetHigh` like DRFR0ST |

---

## Capabilities (`getPluginInfo`)

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

Adjust `supportsSpecialValues` when LO/HI behavior is confirmed from live API.

---

## Mock plugin alignment

Mock **must** expose the same five commands and response bodies as [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md). Differences are internal only:

| Aspect | Mock | LibreLink |
|--------|------|-----------|
| `identifier` | `mockcgm` | `librelink` |
| `requiresLogin` | `false` (wiki) or `true` with any password | `true` |
| `requiresRegionSelection` | `false` | `true` |
| Data | Sine wave | HTTP graph |
| `getDataSources` | One “Mock Sensor” | N followers |

Host code paths are identical: `PluginCgmService` does not branch on vendor.

---

## Implementation technology (open)

| Option | Pros | Cons |
|--------|------|------|
| **Node + DiaKEM/DRFR0ST patterns** | Fastest API port; axios/fetch | Extra runtime unless bundled |
| **Dart standalone** | Same language as team | Reimplement HTTP + redirect |
| **Go static binary** | Single exe per OS | New codebase |

MVP: pick one; protocol doc is language-agnostic.

---

## Out of scope (v1)

- `logbook` endpoint
- `readAveraged` / streaming loops inside plugin
- LO/HI / special values until API samples confirm
- Storing Abbott tokens in host `settings.json` (tokens in SecureStorage only)

---

## Testing without live credentials

1. Mock plugin satisfies all protocol tests.
2. LibreLink plugin unit tests with recorded **redacted** JSON fixtures from `graph` + `connections` (add under `plugins/LibreLink/fixtures/` when implementing).
3. Optional: DRFR0ST test mocks as fixture inspiration (`tests/mocks.ts`).

---

## Open items (fill during implementation)

- [ ] Live `graph` sample: sort order, duplicate latest in `graphData`
- [ ] Confirm `clientVersion` string Abbott accepts in 2026
- [ ] 2FA / status 4 handling UX in host settings
