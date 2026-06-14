# CGM API analysis — template

Copy this file per vendor (e.g. `librelink-api-analysis.md`) and fill in **before** implementing fetch logic in the host or vendor plugin.

**MVP rule:** document what the API actually returns; do not design merge/SQLite/workarounds until a problem is observed in these samples.

---

## Plugin identity

| Field | Value |
|-------|-------|
| Plugin id | e.g. `librelink` |
| Vendor API | e.g. LibreLink Up REST |
| Analyst / date | |
| Environment | sandbox / production / mock |

---

## Endpoints or commands used

| Call | Purpose | Host plugin command |
|------|---------|---------------------|
| | Current glucose | `getCurrentReading` |
| | History window | `getHistory` |
| | Other | |

---

## Sample: current reading

Paste redacted JSON (no tokens, no real names).

```json

```

| Field | Type | Notes |
|-------|------|-------|
| timestamp | | TZ, precision |
| value | | mg/dL? mmol? |
| trend | | enum / arrow |
| special | LO/HI? | |

---

## Sample: history

Paste redacted JSON (truncate if huge; note total count and time span).

```json

```

| Question | Answer |
|----------|--------|
| Sort order | ascending / descending / unsorted |
| Sample interval | ~5 min? irregular? |
| Includes latest point? | yes / no / duplicate of current |
| Max window returned | hours / count cap |
| Stable across polls? | same window / grows / shrinks |
| Identifiers per row | UUID / time only |

---

## MVP fetch proposal

After samples, choose one (check one):

- [ ] **Single call** — history enough; `latest = last`
- [ ] **Two calls** — current for tray, history for chart; no dedupe in host v1
- [ ] **Plugin combines** — plugin returns `{ latest, series }` after internal normalize

**Host after fetch (v1):**

```text
connectionHistory[id] = <series from above>
latest for tray = <explicit latest or series.last>
trim to chartDurationHours
```

---

## Observed problems

Fill only when seen in real samples or MVP demo — not speculatively.

| # | Symptom | Sample evidence | MVP fix? | Deferred? |
|---|---------|-----------------|----------|-----------|
| 1 | | | | |
| 2 | | | | |

---

## Rate limits & errors

| Case | Behavior |
|------|----------|
| 401 / expired session | |
| Empty history | |
| Timeout | |

---

## Sign-off

- [ ] Samples attached or linked (redacted)
- [ ] MVP fetch proposal agreed
- [ ] Mock plugin updated to match contract
- [ ] Ready to implement host fetch (spec 05 MVP slice)
