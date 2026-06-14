# Multi-vendor CGM plugin design

How Nivo supports **LibreLink**, **Dexcom**, **Nightscout**, and future vendors without baking one vendor’s HTTP shape into the host or into other plugins.

**Host contract:** [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) (unchanged principle: JSON lines, subprocess, frozen binary per OS).

---

## Core rule: one plugin per vendor, not one plugin for all CGMs

| Do | Don’t |
|----|--------|
| `librelink` — Abbott HTTP inside | Single “universal CGM” plugin with `if (vendor == dexcom)` |
| `nightscout` — Nightscout REST inside | Shared vendor HTTP in the Flutter app |
| `com.nivo.dexcom` — Dexcom API inside | Copy LibreLink endpoint classes into Dexcom tree |

The **host** stays vendor-agnostic. Each **plugin** owns that vendor’s endpoints, auth, and mapping.

Optional later: a tiny **protocol helper** package (stdin loop, JSON encode) copied or vendored by authors — not shared business logic.

---

## What the host guarantees (all vendors)

Same five connection points + one poll optimization:

| Host command | Purpose |
|--------------|---------|
| `getPluginInfo` | Identity + **capabilities** (feature flags) |
| `authenticate` | Establish session; return `sessionOptions` for disk |
| `getDataSources` | List monitorable targets (`id` + `name`) |
| `fetchReadings` | **Preferred poll:** `current` + `history` in one IPC message |
| `getCurrentReading` / `getHistory` | Legacy/split; still required for compatibility |

The host **never** calls Abbott, Dexcom, or Nightscout directly.

### Poll strategy (capability-driven)

| `supportsCombinedFetch` | Host behavior on each poll |
|-------------------------|---------------------------|
| `true` | One `fetchReadings` command |
| `false` | One subprocess: `getCurrentReading` then `getHistory` (held session) |

Vendors differ internally; the host only checks the flag.

---

## Vendor comparison (planning)

### Connections (“data sources”)

| Vendor | Created via API? | `getDataSources` maps to |
|--------|------------------|---------------------------|
| **LibreLink Up** | No — follow in mobile app | `GET /llu/connections` → each `patientId` |
| **Dexcom** | No — paired in Dexcom flow | Share/Clarity: device or patient list (API-specific) |
| **Nightscout** | N/A — one site per URL | Often **one** synthetic source: `{ id: "default", name: site name }` |
| **xDrip upload / others** | Varies | Analysis doc per vendor |

Nivo **connections** (`CgmConnection`) are always: plugin id + `patientId` (= plugin `dataSourceId`) + display name.

### Auth (plugin `authenticate` + `sessionOptions`)

| Vendor | Typical `authenticate` inputs | Persist in `sessionOptions` |
|--------|------------------------------|-----------------------------|
| LibreLink | email, password | `apiBaseUrl`, `accountIdHash`, `clientVersion` |
| Dexcom | email/password or OAuth code | tokens, refresh token, region, user id |
| Nightscout | base URL + API secret (or token) | `baseUrl`, `apiSecret` (host secure storage for secrets) |

Host UI can stay generic (username/password fields) until we add **capability-driven auth UI** (e.g. `authKind: urlSecret` → show URL + token fields). Not required for protocol v1.

### Fetch shape (plugin internal — not host)

| Vendor | Typical HTTP | Plugin internal pattern | `fetchReadings` |
|--------|--------------|-------------------------|-----------------|
| **LibreLink** | 1× `GET …/graph` | Endpoint per path; `GraphService` | One call → map current + `graphData` |
| **Nightscout** | `GET /api/v1/entries.json` | `EntriesEndpoint`; current = last in window | One call → filter/sort entries |
| **Dexcom** | Often 2+ calls (latest EGV + range) | `LatestEgvEndpoint` + `HistoryEndpoint`; service composes | One **command**, N HTTP calls inside plugin |
| **Mock** | None | Generator | One command |

**Important:** `fetchReadings` means “one **host** round-trip”, not “one **vendor** HTTP request”. Dexcom plugins may still perform multiple HTTP calls inside `fetchReadings`.

---

## Recommended plugin internal layout (any vendor)

Same structure as LibreLink; names vary by vendor:

```text
plugins/<VendorName>/
  plugin.json
  bin/<platform-id>/...
  lib/
    transport/          # HTTP client, headers, errors (one class)
    endpoints/          # ONE Abbott/Dexcom/Nightscout path per file
    services/           # Orchestrate endpoints (auth, fetch snapshot)
    mappers/            # Vendor JSON → protocol { value, trend, timestamp }
    protocol_dispatch.dart
```

| Layer | Responsibility |
|-------|----------------|
| **Endpoint** | Single HTTP method + path; parse JSON; throw on HTTP errors |
| **Service** | Business flow (login + redirect; fetch graph; paginate entries) |
| **Mapper** | Pure functions: vendor model → protocol reading |
| **Protocol dispatch** | Map `command` → service; no HTTP |

---

## Example: Nightscout (sketch)

**Endpoints (one file each):**

| Class | HTTP |
|-------|------|
| `StatusEndpoint` | `GET /api/v1/status.json` (optional health) |
| `EntriesEndpoint` | `GET /api/v1/entries.json?count=…` or date range |

**`authenticate`:** validate URL + `API-SECRET` header; return token in `authToken`, store `baseUrl` in `sessionOptions`.

**`getDataSources`:** return one source unless plugin supports multiple configured sites (host would store multiple connections).

**`fetchReadings`:**

1. `EntriesEndpoint.fetch(since: now - hours)`
2. Mapper: sort asc; `current` = last entry; `history` = all in range

No LibreLink graph endpoint; still exposes `supportsCombinedFetch: true`.

---

## Example: Dexcom (sketch)

Depends on which API (official OAuth vs community). Typical internal split:

| Class | Responsibility |
|-------|----------------|
| `OAuthTokenEndpoint` | Exchange / refresh tokens |
| `DevicesEndpoint` or `PatientsEndpoint` | List `getDataSources` |
| `LatestGlucoseEndpoint` | Current EGV |
| `GlucoseHistoryEndpoint` | Range for chart |

**`fetchReadings`:** service calls latest + history (or one endpoint if API provides both), maps to protocol, returns once.

Capabilities: `supportsMultipleDataSources` per API; `requiresRegionSelection` if applicable; usually `supportsSpecialValues: true`.

---

## Host app: what we should **not** change per vendor

| Stay generic | Avoid |
|--------------|--------|
| `CgmService` / `PluginCgmService` | `if (pluginId == 'dexcom')` in notifier |
| `CgmSession` + `pluginSettings` | Hard-coded LibreLink fields in settings UI (use capabilities later) |
| `GlucoseSnapshot` poll path | Vendor-specific merge in host ([ADR 003](../adr/003-plugin-canonical-history-no-merge.md)) |
| Plugin catalog discovery | Bundling all vendors into one binary |

---

## Capabilities today and extensions (optional)

Already in protocol v1:

| Capability | Use |
|------------|-----|
| `supportsMultipleDataSources` | Multi-patient / multi-site |
| `supportsHistory` | Chart + `fetchReadings` history array |
| `maxHistoryHours` | Clamp `hours` |
| `supportsSpecialValues` | LO / HI |
| `requiresRegionSelection` | LibreLink-style region (Dexcom may reuse for EU/US) |
| `supportsCombinedFetch` | Host uses `fetchReadings` on poll |
| `apiVersion` | `"1"` |

Future (only when building auth UI or streaming):

| Proposed | Use |
|----------|-----|
| `authKind` | `password` \| `urlSecret` \| `oauth` — drives settings form |
| `supportsStreaming` | Plugin pushes readings (v2 protocol; not MVP) |

Add new flags only when the host **reads** them; otherwise document in plugin README.

---

## MVP order (suggested)

1. **Mock** — protocol reference, `fetchReadings` ✅  
2. **LibreLink** — follower API, combined graph ✅  
3. **Nightscout** — implemented in `plugins/Nightscout` ✅  
4. **Dexcom** — OAuth + legal/API stability analysis first  
5. Others (Glooko, CareLink, etc.) — analysis doc each, separate plugin id  

Each vendor: `docs/plugins/<vendor>-api-analysis.md` before code.

---

## Checklist: new vendor plugin

- [ ] API analysis doc (endpoints table, auth, rate limits)
- [ ] One endpoint class per HTTP path
- [ ] `fetchReadings` if vendor can supply current + history (even via multiple internal HTTP calls)
- [ ] `getPluginInfo.capabilities` accurate
- [ ] `sessionOptions` documented for host persistence
- [ ] No host changes unless new capability needs UI support

---

## References

- [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) — including `fetchReadings`
- [librelink-api-analysis.md](librelink-api-analysis.md) — LibreLink endpoint table
- [ADR 029](../adr/029-plugin-ecosystem.md) — one binary per OS, any language
- [ADR 003](../adr/003-plugin-canonical-history-no-merge.md) — normalize in plugin, not host
