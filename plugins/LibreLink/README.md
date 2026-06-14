# LibreLink Up plugin

Nivo CGM plugin for **LibreLink Up** (caregiver / follower accounts).

- **Identifier:** `librelink`
- **Protocol:** [PLUGIN-PROTOCOL-V1](../../docs/plugins/PLUGIN-PROTOCOL-V1.md)
- **API notes:** [librelink-api-analysis.md](../../docs/plugins/librelink-api-analysis.md)

## Build

From the repo root:

```bash
dart run tool/glucose_plugin.dart build plugins/LibreLink
```

Output: `plugins/LibreLink/dist/librelink.nivoplugin` (one executable file, like `LibreLink` in Nivo_mac)

## Install into Nivo

Drag **`dist/librelink.nivoplugin`** into **Settings → Plugins**, or use **Choose plugin file…**.

Restart Nivo → **Reload** → **Data Source** to sign in.

## Optional `pluginSettings`

Stored automatically after sign-in:

| Key | Purpose |
|-----|---------|
| `apiBaseUrl` | Regional LibreLink API host (set after login redirect) |
| `accountIdHash` | SHA-256 of account id for `Account-Id` header |
| `clientVersion` | App version string sent to Abbott (default `4.16.0`) |

You can set `region` in `pluginSettings` before first login (e.g. `eu`, `us`) to pick an initial API host; wrong regions are corrected via Abbott’s redirect flow.

## Requirements

- A **LibreLink Up** account that follows at least one patient
- Network access to `*.libreview.io`
- Complete any 2FA / onboarding steps in the official app before signing in here
