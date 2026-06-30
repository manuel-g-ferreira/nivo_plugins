# Plugin catalog (source)

`catalog.json` for the public **[nivo-plugin-catalog](https://github.com/manuel-g-ferreira/nivo-plugin-catalog)** repo is **built here** in `nivo-plugins`.

| File | Role |
|------|------|
| `catalog.json` | Generated catalog — committed on each release PR, refreshed from binaries on tag publish |

## Build locally

From manifest metadata (no `.nivo` files required):

```bash
dart run tool/release.dart publish catalog from-plugins \
  --plugins plugins \
  --repo manuel-g-ferreira/nivo-plugin-catalog \
  --output catalog/catalog.json
```

From staged release assets (after CI or local matrix build):

```bash
dart run tool/release.dart publish catalog from-assets \
  --assets release \
  --plugins plugins \
  --repo manuel-g-ferreira/nivo-plugin-catalog \
  --output catalog/catalog.json
```

## Release flow

1. **Release PR** — `prepare` bumps plugin versions and regenerates `catalog/catalog.json`.
2. **Tag push** — CI builds `.nivo` packages, rebuilds catalog from assets, publishes to `nivo-plugin-catalog` (`catalog.json` + `dist/` + GitHub Release).

Do not edit `catalog.json` by hand unless you know what you are doing.
