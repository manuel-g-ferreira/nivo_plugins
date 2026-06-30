# Nivo Plugins CI & releases

Two workflows, five shared actions. Plugin packages use the **`.nivo`** extension.

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [merge-request.yml](../../.github/workflows/merge-request.yml) | PR and push to `main` | Format ∥ tests → smoke → cross-platform builds |
| [release.yml](../../.github/workflows/release.yml) | Manual dispatch, merged `release/*` PR, tag push | Release PR → tag → package → public catalog |

Desktop app CI lives in [nivo](https://github.com/manuel-g-ferreira/nivo).

## Actions

| Action | Role |
|--------|------|
| [setup](../../.github/actions/setup) | Dart SDK + all plugin `pub get` |
| [tool-setup](../../.github/actions/tool-setup) | Root `pub get` for release scripting |
| [release-auth](../../.github/actions/release-auth) | Require `NIVO_RELEASE_TOKEN` + git bot identity (private repo) |
| [catalog-publish-auth](../../.github/actions/catalog-publish-auth) | Resolve `GH_TOKEN` for `nivo-plugin-catalog` publish |
| [plugin-build](../../.github/actions/plugin-build) | Compile one plugin (optional `.nivo` package) |

## Merge request

| Job | Steps |
|-----|-------|
| **Format** | checkout → setup → format |
| **Analyze** | checkout → setup → `dart analyze --fatal-infos` |
| **Unit tests** | checkout → setup → `dart test` |
| **Plugin tests · {plugin}** | LibreLink, DexcomShare, Nightscout mapper/protocol unit tests |
| **Protocol smoke** | build all 4 plugins on Linux → `getPluginInfo` |
| **Build · {plugin} ({os})** | matrix 4×3 — compile check |

## Release flow

**Secrets**

| Secret | Purpose |
|--------|---------|
| `NIVO_RELEASE_TOKEN` | PAT with `contents` + `pull-requests` write on **private** `nivo-plugins` |
| `NIVO_PLUGINS_PUBLIC_TOKEN` | (optional) PAT with `contents` write on the **public** catalog repo; falls back to `NIVO_RELEASE_TOKEN` |

**Variables**

| Variable | Purpose |
|----------|---------|
| `NIVO_PLUGINS_PUBLIC_REPO` | `owner/repo` for the public catalog (default: `manuel-g-ferreira/nivo-plugin-catalog`) |

1. **Bootstrap** — create public repo from [dist-repo](../../dist-repo/) (README only; catalog is built in `catalog/` here).
2. **Actions → Release → Run workflow** (leave tag empty).
3. Merge the **Release X.Y.Z** PR — includes updated `catalog/catalog.json`.
4. Tag push builds `.nivo` assets, rebuilds `catalog/catalog.json` from binaries, and publishes to **`nivo-plugin-catalog`**.

**Retry:** Run **Release** with an existing tag.

## Release assets

Catalog-compatible naming:

```text
dist/{plugin-id}-{platform-id}.nivo
dist/{plugin-id}-{platform-id}.nivo.sha256
```

Platform ids: `darwin-arm64`, `darwin-x64`, `linux-x64`, `windows-x64`.

`catalog.json` download URLs use `raw.githubusercontent.com/.../dist/...` so the Nivo app can install plugins in **Settings → Plugins → Available**.

GitHub Releases attach the same `.nivo` files for browser download.

## Local tooling

```bash
# Stage downloaded CI artifacts
dart run tool/release.dart publish stage --dist dist --output release

# Generate catalog/catalog.json from plugin manifests (release PR)
dart run tool/release.dart publish catalog from-plugins \
  --plugins plugins \
  --repo manuel-g-ferreira/nivo-plugin-catalog \
  --output catalog/catalog.json

# Rebuild from staged .nivo assets (tag publish)
dart run tool/release.dart publish catalog from-assets \
  --assets release \
  --plugins plugins \
  --repo manuel-g-ferreira/nivo-plugin-catalog \
  --output catalog/catalog.json

# Publish catalog + dist to nivo-plugin-catalog (requires gh CLI + GH_TOKEN)
dart run tool/release.dart publish public \
  --catalog catalog/catalog.json \
  --assets release \
  --repo manuel-g-ferreira/nivo-plugin-catalog \
  --tag v1.0.0 \
  --title "Nivo Plugins 1.0.0" \
  --notes release-notes.md
```

Users add the catalog in Nivo via **Settings → Plugins → Available → Add source**:

```text
https://raw.githubusercontent.com/manuel-g-ferreira/nivo-plugin-catalog/main/catalog.json
```
