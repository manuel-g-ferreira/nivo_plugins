# Nivo Plugins CI & releases

## Workflows

Modular layout — shared jobs live in reusable workflows; entry points only wire triggers.

| Workflow | When it runs | Role |
|----------|----------------|------|
| [plugins.yml](../../.github/workflows/plugins.yml) | PR and push to `main` (path filters) | CI checks + plugin builds + integration smoke |
| [prepare-release.yml](../../.github/workflows/prepare-release.yml) | Manual (**Run workflow**) | Opens a `release/*` PR (version + changelog, no tag) |
| [finish-release.yml](../../.github/workflows/finish-release.yml) | `release/*` PR merged to `main` | Tags merge commit, runs **Release** |
| [release.yml](../../.github/workflows/release.yml) | Chained from Finish release, or manual | CI checks + plugin builds + GitHub Release |
| [ci-checks.yml](../../.github/workflows/ci-checks.yml) | *(reusable only)* | Format and unit tests |
| [build-plugins.yml](../../.github/workflows/build-plugins.yml) | *(reusable only)* | Cross-platform plugin builds + integration smoke |

Desktop app CI and releases run in [nivo](https://github.com/manuel-g-ferreira/nivo).

## Release channels

### Stable

- **Tag:** `v1.0.0`, `v1.0.1`, … (semver, no suffix)
- **GitHub:** normal release (`prerelease: false`)

### Beta

- **Tag:** `v1.1.0-beta.1`, `v1.1.0-beta.2`, …
- **GitHub:** pre-release (`prerelease: true`)

## Creating a release (maintainers)

### Recommended flow (works with branch protection)

1. Open **Actions** → **Prepare release** → **Run workflow**
2. Choose **channel** (`stable` or `beta`) and **bump** (`patch`, `minor`, `major`)
3. Review the opened **Release X.Y.Z** pull request (branch `release/X.Y.Z`)
4. **Merge** the PR when ready

After merge, **Finish release** automatically:

- Creates and pushes tag `vX.Y.Z`
- Runs **Release** (CI checks → plugin builds → `.nivoplugin` assets → GitHub Release)

No direct push to `main` from Actions.

Optional: add notes under `## [Unreleased]` before step 1, or edit the `release/*` branch before merging.

### Recovery

If **Release** fails after the tag exists: **Actions** → **Release** → **Run workflow** and enter the tag (e.g. `v1.0.4-beta.1`).

### Manual release (advanced)

<details>
<summary>Without Prepare release workflow</summary>

1. PR with version bump + changelog to `main`, merge
2. `git tag vX.Y.Z && git push origin vX.Y.Z`
3. Dispatch **Release** with that tag if the tag push did not start it

</details>

## Local CI (before push)

Run the same commands as the PR workflow jobs:

```bash
dart format --output=none --set-exit-if-changed .
dart test
dart run tool/glucose_plugin.dart build --no-package plugins/MockCGM
dart run tool/glucose_plugin.dart build --no-package plugins/LibreLink
dart run tool/glucose_plugin.dart build --no-package plugins/Nightscout
echo '{"command":"getPluginInfo"}' | plugins/MockCGM/bin/linux-x64/mock-cgm | head -1 | grep -q '"success":true'
```

## Release tooling

Release automation lives in `tool/release.dart` (Dart CLI). Common commands:

```bash
dart run tool/release.dart prepare --channel stable --bump patch --no-tag
dart run tool/release.dart tag
dart run tool/release.dart changelog extract 1.0.0
dart run tool/release.dart publish stage --dist dist --output release
```

Run `dart pub get` (or CI **dart-setup**) before `dart run tool/release.dart`.

## CI jobs (pull requests)

Each check appears separately on the PR:

| Job | Runner | What it does |
|-----|--------|--------------|
| **Format** | `ubuntu-latest` | `dart format --set-exit-if-changed` |
| **Unit tests** | `ubuntu-latest` | `dart test` |
| **Build · {plugin} ({os})** | matrix | Compile plugin binary per platform |
| **Integration (protocol smoke)** | `ubuntu-latest` | Build all plugins → pipe `getPluginInfo` |

Release runs the same checks and builds, then packages `.nivoplugin` assets on a GitHub Release.

## Version alignment check

Release workflow validates:

```text
tag v1.2.3  →  pubspec version 1.2.3  (exact match)
```

Mismatch → failed release.

All first-party plugins are versioned together with the repo tag (monorepo release).

## Release assets

Each platform ships a versioned `.nivoplugin` file. Each file has a **`.sha256` sidecar** on the same GitHub Release.

Naming pattern (same idea as Nivo app archives):

```text
NivoPlugins-{version}-{plugin-id}-{platform}.nivoplugin
NivoPlugins-{version}-{plugin-id}-{platform}.nivoplugin.sha256
```

Examples for `1.0.1-beta.1`:

| Plugin | macOS | Windows | Linux |
|--------|-------|---------|-------|
| MockCGM | `NivoPlugins-1.0.1-beta.1-mockcgm-macos.nivoplugin` | `…-windows.nivoplugin` | `…-linux.nivoplugin` |
| LibreLink | `…-librelink-macos.nivoplugin` | `…-windows.nivoplugin` | `…-linux.nivoplugin` |
| Nightscout | `…-nightscout-macos.nivoplugin` | `…-windows.nivoplugin` | `…-linux.nivoplugin` |

**Note:** GitHub Actions **workflow artifacts** are for CI debugging — not for end users. Download assets from the **GitHub Release** page instead.

Install into Nivo via Settings → Plugins or `dart run tool/install_plugin.dart` from the app repo.

## Not in CI (MVP)

- macOS notarization for plugin binaries (ad-hoc codesign on macOS runners only)
- Automated plugin catalog sync into the Nivo app repo
