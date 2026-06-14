# Nightscout plugin

Nivo CGM plugin for self-hosted [Nightscout](https://nightscout.github.io/) sites.

- **Identifier:** `nightscout`
- **Protocol:** [PLUGIN-PROTOCOL-V1](../../docs/plugins/PLUGIN-PROTOCOL-V1.md)

## Sign in (Nivo Data Source)

| Field | Value |
|-------|--------|
| **Username** | Your Nightscout site URL (e.g. `https://myname.herokuapp.com`) |
| **Password** | Your site `API_SECRET` (plain text — the plugin sends SHA1 in the `api-secret` header) |

Optional: set `accessToken` in plugin settings (advanced) to use token auth instead of API secret.

After sign-in, add a connection — the plugin exposes one data source per site (`default`).

## Build

```bash
dart run tool/glucose_plugin.dart build plugins/Nightscout
```

Output: `plugins/Nightscout/dist/nightscout.nivoplugin`

## Install into Nivo

Drag **`dist/nightscout.nivoplugin`** into **Settings → Plugins**.

## Internal layout

| Module | HTTP |
|--------|------|
| `StatusEndpoint` | `GET /api/v1/status.json` |
| `EntriesEndpoint` | `GET /api/v1/entries.json` |
| `EntriesService` | Maps `sgv` entries → `fetchReadings` |

## sessionOptions (persisted automatically)

| Key | Purpose |
|-----|---------|
| `baseUrl` | Normalized site URL |
| `apiSecretHash` | SHA1 hex of API secret |
| `accessToken` | Optional Nightscout access token |
