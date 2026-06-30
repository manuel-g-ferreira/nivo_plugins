# Nightscout API — analysis

**Plugin id:** `nightscout`  
**Implementation:** `plugins/Nightscout/`

## Overview

Nightscout exposes a REST API on the user's site base URL. Nivo reads **CGM entries** (`type: sgv`) only; treatments and profiles are out of scope for MVP.

## HTTP endpoints (plugin internal)

| Method | Path | Responsibility |
|--------|------|----------------|
| `GET` | `/api/v1/status.json` | Auth probe / site health |
| `GET` | `/api/v1/entries.json` | Glucose time series |

### Entries query

```
GET /api/v1/entries.json?find[date][$gte]={ms}&count=2000
```

- `find[date][$gte]` — Unix ms UTC, start of history window  
- Filter to `sgv` entries in the plugin mapper  
- Current reading = latest `sgv` in window (or latest fetch for `getCurrentReading`)

## Authentication

| Method | Detail |
|--------|--------|
| API secret | Header `api-secret: {sha1(API_SECRET)}` lowercase hex |
| Access token | Query `?token=...` or persisted in `sessionOptions.accessToken` |

Nivo sign-in mapping:

| Nivo field | Nightscout |
|------------------|------------|
| Username | Site URL |
| Password | API secret (plain; plugin hashes) |

## Host protocol mapping

| Command | Implementation |
|---------|----------------|
| `authenticate` | Status or entries probe |
| `getDataSources` | Single source `default` named from site host |
| `fetchReadings` | One entries fetch → current + history |
| `getCurrentReading` / `getHistory` | Same entries data (split) |

## References

- [Nightscout API v1 Security](https://github.com/nightscout/cgm-remote-monitor/wiki/API-v1-Security)
- `plugins/Nightscout/` — reference implementation
