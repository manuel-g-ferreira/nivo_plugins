# Mock CGM — API analysis

**Plugin id:** `mockcgm`  
**Protocol:** [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md)  
**Purpose:** Reference plugin with **identical host connection points** as LibreLink and future vendors.

---

## Vendor API

None (synthetic). Internal generator only.

---

## MVP fetch proposal

| Host command | Internal |
|--------------|----------|
| `getPluginInfo` | Static metadata + capabilities |
| `authenticate` | Always success; token `mock-token`, userId `mock-user` |
| `getDataSources` | `[{ id: "mock-sensor-1", name: "Mock Sensor" }]` |
| `getCurrentReading` | `value` from sine at `now`, trend from derivative |
| `getHistory` | Samples every 5 min for `hours` (1–24), same phase function |

**Shared state:** One phase clock so current and history are consistent when host calls both in one fetch.

---

## Response shapes

Must match [PLUGIN-PROTOCOL-V1.md](PLUGIN-PROTOCOL-V1.md) exactly (field names, types, trend strings, ISO timestamps).

Example `getCurrentReading` success:

```json
{
  "success": true,
  "value": 112,
  "trend": "fortyFiveUp",
  "timestamp": "2026-05-30T14:05:00.000Z",
  "specialValue": null
}
```

---

## Capabilities

```json
{
  "supportsMultipleDataSources": false,
  "supportsHistory": true,
  "maxHistoryHours": 24,
  "supportsSpecialValues": false,
  "requiresRegionSelection": false,
  "apiVersion": "1"
}
```

---

## Observed problems

None expected (synthetic). Use for host/protocol CI only.

---

## Sign-off

- [x] Protocol alignment defined
- [ ] Plugin binary implements PLUGIN-PROTOCOL-V1
- [ ] Host `plugin_process_test` uses mock executable
