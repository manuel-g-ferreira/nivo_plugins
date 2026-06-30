# Mock CGM plugin

Reference plugin (`mockcgm`) for dev and CI. Speaks [PLUGIN-PROTOCOL-V1](../../docs/PLUGIN-PROTOCOL-V1.md).

Generates **realistic 5-minute CGM series** with selectable test scenarios (in-range, highs, lows, urgent lows).

## Build

```bash
dart run tool/glucose_plugin.dart build plugins/MockCGM
```

Binary: `plugins/MockCGM/bin/<platform-id>/mock-cgm` → `dist/mockcgm.nivo`

## Install

Drag `dist/mockcgm.nivo` into **Settings → Plugins**, then enable **Mock CGM** under **Connections**.

## Scenarios

Choose under **Sign in → Scenario** (password can be anything):

| Scenario | Glucose pattern | Use for |
|----------|-----------------|---------|
| **Full cycle** (default) | ~4 h loop: in-range → high (~205) → low (~65) → urgent low (~52) → recovery | Alerts, delta, chart, menu-bar colors |
| **Stable in range** | ~110 mg/dL flat | Baseline UI |
| **Sustained high** | ~195 mg/dL | High threshold / color |
| **Sustained low** | ~65 mg/dL | Low threshold / color |
| **Sustained urgent low** | ~52 mg/dL | Urgent low alerts |
| **Sustained urgent high** | ~265 mg/dL | Urgent high alerts |

The **cycle** repeats every 4 hours with smooth curves and small sensor noise (±2 mg/dL).

## Layout

- `plugin.json` — manifest
- `lib/mock_glucose.dart` — scenario generator
- `lib/protocol_dispatch.dart` — protocol handlers
- `bin/mock_cgm_plugin.dart` — compiled entrypoint
