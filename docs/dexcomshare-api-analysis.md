# Dexcom Share API (unofficial)

Reference implementation: [GlucoseBar DexcomShare.swift](https://github.com/t1dtools/GlucoseBar/blob/main/GlucoseBar/Providers/DexcomShare/DexcomShare.swift).

## Overview

Dexcom Share is an **unofficial** REST API used by the Dexcom mobile app’s follower feature. Nivo uses the same endpoints as GlucoseBar and [pydexcom](https://github.com/gagebenne/pydexcom).

## Regions

| Region key | Base URL | Application ID |
|------------|----------|----------------|
| `us` | `https://share2.dexcom.com/ShareWebServices/Services` | `d89443d2-327c-4a6f-89e5-496bbb0317db` |
| `ous` | `https://shareous1.dexcom.com/ShareWebServices/Services` | same as US |
| `jp` | `https://share.dexcom.jp/ShareWebServices/Services` | `d8665ade-9673-4e27-9ff6-92db4ce13d13` |

References: [pydexcom](https://github.com/gagebenne/pydexcom), [DiaKEM dexcom-api-client](https://github.com/DiaKEM/dexcom-api-client).

## Application ID

Hardcoded client ID (public, used by Share clients):

`d89443d2-327c-4a6f-89e5-496bbb0317db`

## Authentication

Two-step login:

1. `POST /General/AuthenticatePublisherAccount`
   - Body: `{ accountName, password, applicationId }`
   - Response: quoted JSON string → account UUID

2. `POST /General/LoginPublisherAccountById`
   - Body: `{ accountId, password, applicationId }`
   - Response: quoted JSON string → session UUID

## Glucose data

`POST /Publisher/ReadPublisherLatestGlucoseValues`

Query parameters (pydexcom / DiaKEM style):

- `sessionId`
- `minutes` (1–1440)
- `maxCount` (1–288)

Body: `{}`

GlucoseBar also sends JSON body `{ sessionId, minutes, maxCount }`; Nivo uses query params.

Response: array of `{ WT, ST, DT, Value, Trend }`.

- `WT`: wall time as `Date(epochMs)`
- `Value`: mg/dL integer
- `Trend`: `Flat`, `SingleUp`, `FortyFiveUp`, etc.

## Session errors

| Code | Action |
|------|--------|
| `SessionIdNotFound` | Re-authenticate |
| `SessionNotValid` | Re-authenticate |

## Requirements

- Primary Dexcom account with Share enabled
- At least one follower in the Dexcom app
- 2FA / email verification may block automated login

## Nivo plugin mapping

| Protocol field | Source |
|----------------|--------|
| `authToken` | session UUID |
| `userId` | account UUID |
| `sessionOptions.region` | `us` / `ous` |
| `sessionOptions.accountId` | account UUID |
| `sessionOptions.sessionId` | session UUID |
