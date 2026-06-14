# Dexcom

Nivo CGM plugin for Dexcom via **Dexcom Share** (unofficial REST API, same flow as [GlucoseBar](https://github.com/t1dtools/GlucoseBar)).

Requires Share enabled on your Dexcom account and at least one follower in the Dexcom app.

## Sign in

| Field | Value |
|-------|--------|
| Email | Dexcom account email |
| Password | Dexcom account password |
| Region | **United States** or **Outside USA** |

## Build

```bash
dart run tool/glucose_plugin.dart build plugins/DexcomShare
```

Install `dist/dexcomshare.nivoplugin` via **Settings → Plugins**.

## Session options

After sign-in, the host stores:

| Key | Meaning |
|-----|---------|
| `region` | `us` or `ous` |
| `accountId` | Dexcom account UUID |
| `sessionId` | Share session UUID (also `authToken`) |

## API

Uses Dexcom Share endpoints (see `docs/dexcomshare-api-analysis.md`):

- `POST /General/AuthenticatePublisherAccount`
- `POST /General/LoginPublisherAccountById`
- `POST /Publisher/ReadPublisherLatestGlucoseValues`
