# Changelog

## 0.3.0 - 2026-07-28
### Added
 * Simulate mode in `TrimAllNDS.command`, mirroring the binary's `-s` flag: reports the space
   that would be saved without modifying anything.
 * `TrimAllNDS.command` now accepts explicit file arguments, so it can be driven from a terminal
   as well as by double-click.
 * Prebuilt binaries for AARCH64 (Apple Silicon) macOS.
 * `TrimAllNDS.command` is now included in the release archives.

### Changed
 * Merged upstream `Nemris/ndstrim`, bringing a header-parsing refactor and Thin LTO in place of
   Full LTO for release builds.
 * Release builds now use `taiki-e/upload-rust-binary-action`, building the Windows and macOS
   flavors natively rather than cross-compiling.
 * `TrimAllNDS.command` writes trimmed copies to a temporary file and renames them into place, so
   an interrupted run can no longer leave behind a partial ROM that looks valid.
 * Trimming in place via `TrimAllNDS.command` now requires an explicit confirmation.
 * `TrimAllNDS.command` computes CRC-16 from a lookup table rather than bit-at-a-time.
 * The version reported by `ndstrim --version` now matches the release it ships in; it had been
   stuck at 0.2.1 since the fork.

### Fixed
 * `TrimAllNDS.command` copied the entire untrimmed ROM before truncating it, so producing an
   8 KiB file from a 64 MiB ROM wrote roughly 64 MiB. Copies are now bounded to the trimmed
   length. Besides the wasted throughput, trimming had required free space equal to the original
   ROM's size, which could fail on a nearly-full card.
 * Directories whose names end in `.nds` no longer cause a spurious error during the scan.

## 0.2.3 - 2026-07-09
### Changed
 * Replace `bincode` and `serde` with `bytemuck`.
 * Adopt the `crc` crate for slightly faster NDS verification.
 * Bump dependencies to latest and update to Rust's 2024 edition.

## 0.2.2 - 2026-07-06
### Added
 * `TrimAllNDS.command`, a double-clickable macOS helper that trims every ROM in its directory
   without requiring a Rust toolchain.

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
