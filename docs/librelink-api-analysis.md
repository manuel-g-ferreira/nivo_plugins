# LibreLink Up API — analysis

**Sources reviewed (2026-05-30):**

| Repo | Notes |
|------|--------|
| [DRFR0ST/libre-link-unofficial-api](https://github.com/DRFR0ST/libre-link-unofficial-api) | TypeScript, newer structure, `history()` + `logbook()`, region redirect |
| [DiaKEM/libre-link-up-api-client](https://github.com/DiaKEM/libre-link-up-api-client) | TypeScript, `read()` returns `{ current, history }` explicitly |
| [khskekec gist](https://gist.github.com/khskekec/6c13ba01b10d3018d816706a32ae8ab2) | Referenced by DiaKEM README (detailed API notes) |

**Status:** Analysis complete for MVP plugin design. No host merge; problems logged only when observed in production.

---

## API overview

LibreLink **Up** (caregiver/follower app) talks to regional `libreview.io` hosts, not the patient LibreLink app API.

| Step | Method | Path | Purpose |
|------|--------|------|---------|
| Login | `POST` | `/llu/auth/login` | Email + password → JWT + user |
| Region | `GET` | `/llu/config/country?country=DE` | Resolve `regionalMap[region].lslApi` after redirect |
| Connections | `GET` | `/llu/connections` | Followed patients (data sources) |
| Graph | `GET` | `/llu/connections/{patientId}/graph` | **Current + chart series** |
| Logbook | `GET` | `/llu/connections/{patientId}/logbook` | Manual scan entries (optional, not MVP) |

Default base URL in clients: `https://api-us.libreview.io` (US). Wrong region → login returns redirect → switch `baseURL` to regional `lslApi` and login again.

---

## Required HTTP headers (after login)

| Header | Value |
|--------|--------|
| `Authorization` | `Bearer {authTicket.token}` |
| `product` | `llu.android` |
| `version` | App version string, e.g. `4.12.0` – `4.16.0` (clients differ; may need periodic bumps) |
| `content-type` | `application/json` |
| `Account-Id` | SHA-256 hex of **LibreLink Up account** `user.id` (not patientId) |

Both analyzed repos set these consistently. Session expiry: clients re-login on failure (DiaKEM wrapper) or expect fresh login.

---

## Login

**Request:**

```json
{ "email": "user@example.com", "password": "secret" }
```

**Responses:**

| `status` | Meaning |
|----------|---------|
| `2` | Bad credentials |
| `4` | Extra step required (2FA / onboarding) — DiaKEM surfaces `step.componentName` |
| Redirect payload | `{ "redirect": true, "region": "eu" }` → fetch country map → set regional API URL → retry login |
| Success | `data.authTicket.token`, `data.user` (id, email, country, …) |

**Plugin mapping:**

- `authenticate` → perform login; persist `authToken`, `userId` (= `user.id`), optional `options.region`, `options.apiBaseUrl`, `options.clientVersion`
- `userId` in Nivo session = **follower account id**, not patient id

---

## Connections (data sources)

**GET** `/llu/connections` → `data[]` of connection objects.

Each connection (followed person):

| Field | Use |
|-------|-----|
| `patientId` | **Data source id** for graph URL |
| `firstName`, `lastName` | Display name |
| `targetLow`, `targetHigh` | Patient range (also used to recompute isHigh/isLow in DRFR0ST) |
| `glucoseMeasurement` | Latest reading embedded on connection |
| `glucoseItem` | Often duplicate of latest (same shape) |

**Plugin mapping:**

- `getDataSources` → `{ id: patientId, name: "${firstName} ${lastName}" }` per connection
- `supportsMultipleDataSources: true` when `data.length > 1`
- `defaultDataSourceId` → first connection or last-used patientId in options

---

## Graph (single call for current + history)

**GET** `/llu/connections/{patientId}/graph`

**Response `data` (both repos):**

```typescript
{
  connection: Connection;      // includes glucoseMeasurement
  activeSensors: ActiveSensor[];
  graphData: GlucoseItem[];    // time series
}
```

### `GlucoseItem` (raw sample)

| Field | Type | Notes |
|-------|------|--------|
| `Timestamp` | string | Display/local time string |
| `FactoryTimestamp` | string | Factory time; DiaKEM uses this + `" UTC"` for `Date` |
| `ValueInMgPerDl` | number | Primary value for mg/dL |
| `Value` | number | Often mmol or alternate unit |
| `TrendArrow` | 0–5 optional | See trend table below |
| `isHigh`, `isLow` | boolean | From API |
| `MeasurementColor` | 0–3 | UI color bucket |
| `type` | number | Reading type |

### Trend mapping (both repos align)

| `TrendArrow` | Label |
|--------------|--------|
| 0 | NotComputable |
| 1 | SingleDown |
| 2 | FortyFiveDown |
| 3 | Flat |
| 4 | FortyFiveUp |
| 5 | SingleUp |

Map to Nivo plugin trend strings per [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md).

### Current vs history — **no separate history endpoint**

| Client | Current | History |
|--------|---------|---------|
| **DiaKEM** `read()` | `connection.glucoseMeasurement` | `graphData[]` mapped |
| **DRFR0ST** `read()` | `connection.glucoseItem` | N/A (single point) |
| **DRFR0ST** `history()` | N/A | `graphData[]` |

**MVP conclusion:** One graph fetch per poll inside the plugin. Do not call graph twice for “current” and “history”.

| Command | Plugin implementation |
|---------|----------------------|
| `getCurrentReading` | Map `glucoseMeasurement` (fallback `glucoseItem`) |
| `getHistory` | Filter `graphData` to last `hours` by timestamp; sort ascending |

**Note:** Vendor API does not accept `hours` on the URL. Filtering is **plugin-side** after fetch.

### Ordering / overlap (observe in MVP, do not pre-merge in host)

| Question | Expected (verify with live account) |
|----------|--------------------------------------|
| `graphData` sort order | Likely ascending time; **verify** |
| Latest in `graphData`? | Often duplicates `glucoseMeasurement`; **verify** |
| Window length | ~12–24 h typical; not controlled by `hours` param |
| Stable across polls? | **Verify** — if window shrinks, chart may lose points (acceptable v1) |

---

## Logbook (out of MVP)

**GET** `/llu/connections/{patientId}/logbook` → manual scans. DRFR0ST exposes `logbook()`. Defer unless product needs scan events.

---

## Rate limits & errors

| Case | Behavior in repos |
|------|-------------------|
| HTTP 429 | DRFR0ST: “Too many requests” |
| No connections | Error: account follows no patients |
| Network | Propagate as plugin `networkError` |

Default poll interval 5 min (Nivo) aligns with DiaKEM stream default 90s — avoid sub-minute polling.

---

## Repo comparison (implementation hints)

| Topic | DRFR0ST | DiaKEM |
|-------|---------|--------|
| HTTP | `fetch` | `axios` |
| Region redirect | Recursive `login()` | Recursive `login()` |
| Read shape | Separate `read()` / `history()` | Single `readRaw()` → `{ current, history }` |
| Timestamp parse | `new Date(Timestamp)` | `new Date(FactoryTimestamp + ' UTC')` |
| Connection pick | `patientId` option or first | Name string, function, or first |
| Session refresh | Manual re-login | Auto re-login on error |
| Extra | `logbook`, `stream` | `readAveraged` |

**Recommendation for Nivo LibreLink plugin:** Follow **DiaKEM `readRaw` + `read` split** internally; one graph HTTP call; expose standard five host commands.

---

## MVP fetch proposal (signed off for plugin)

- [x] **Single vendor call per poll** — `GET .../graph`
- [x] **Two host commands** — `getCurrentReading` + `getHistory` read cached graph response in plugin process (no second HTTP call if cache TTL < few seconds)
- [x] **No host merge** — [ADR 003](../adr/003-plugin-canonical-history-no-merge.md)
- [ ] Live sample attached — **pending** (fill section below when available)

### Observed problems (empty until MVP demo)

| # | Symptom | Evidence | Fix |
|---|---------|----------|-----|
| — | — | — | — |

---

## References

- [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) — host ↔ plugin JSON
- [librelink-plugin-considerations.md](librelink-plugin-considerations.md) — plugin design
- [ADR 004 MVP](../adr/004-mvp-analyze-apis-first.md)
