# Changelog

All notable changes to nivo_plugins are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Release tags must match a `## [version]` heading below (enforced in CI).

## [Unreleased]

## [1.0.1-beta.1] - 2026-06-15

### Changed
- Preparing MVP (9e95a5e)
- Declare signIn schemas in CGM plugins. (e83b452)
- Add Dexcom plugin and Nightscout v2 token auth. (425b1de)
- Nivo first-party CGM plugins and release tooling. (6ab2367)


## [1.0.0] - 2026-06-08

### Added
- First-party CGM plugins: MockCGM, LibreLink, Nightscout.
- Plugin authoring CLI (`dart run tool/glucose_plugin.dart`).
- CI workflow for cross-platform plugin builds and protocol smoke tests.
- Dart release tooling and PR-based release flow aligned with Nivo app.
