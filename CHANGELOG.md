# Changelog

## Unreleased
### Added
 * Dependency on `crc` to provide slightly faster NDS verification.
 * Provide builds for AARCH64 macOS.
 * `TrimAllNDS.command`, a double-clickable macOS helper that trims every ROM in its directory
   without requiring a Rust toolchain.

### Changed
 * Replace `bincode` and `serde` with `bytemuck`.
 * Bump dependencies to latest.
 * Update to Rust's 2024 edition.
 * Switch to building Windows and macOS flavors natively.

## 0.2.1 - 2023-06-19
### Added
 * Prebuilt releases are now provided for Linux, Windows and macOS.

### Changed
 * No changes to the code.

## 0.2.0 - 2023-06-18
### Added
 * Possibility to simulate execution.
 * Flag to supply a custom extension for trimmed files.
 * Flag to perform in-place trimming.
 * Lossless trimming to a copy of the ROM.

### Changed
 * Default to lossless instead of in-place trimming.

## 0.1.0 - 2023-05-25
### Added
 * Initial release.
