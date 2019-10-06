# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]


## [1.2.1] - 2019-10-06

This fixes issues with safe media detection.

### Changed

- Adds extra safe-guard, rejecting devices larger than 64 GiB.

### Fixed

- Devices that report as `ejectable`, but not `removable`, were incorrectly rejected by safety checks.


## [1.2.0] - 2019-09-25

This actually implements the `--verify` option for `flasher write`.

### Added

- `flasher write --verify` is actually implemented

### Fixed

- Device selection, and sanity checks incorrectly rejected devices that had a
  bare device ISO 9660 filesystem mounted.


## [1.1.0] - 2019-09-23

This lowers the bar for supported macOS version to 10.13+.

### Changed

- Implements fallbacks for unavailable APIs for macOS 10.13+


## [1.0.0] - 2019-09-22

This is the initial release of `flasher`, supporting macOS 10.15+ only.

### Added

- `flasher list` command, to list suitable devices
- `flasher write` command, to write an image to a device


[Unreleased]: https://github.com/notCalle/flasher/compare/v1.2.1..HEAD
[1.2.1]: https://github.com/notCalle/flasher/compare/v1.2.0..v1.2.1
[1.2.0]: https://github.com/notCalle/flasher/compare/v1.1.0..v1.2.0
[1.1.0]: https://github.com/notCalle/flasher/compare/v1.0.0..v1.1.0
[1.0.0]: https://github.com/notCalle/flasher/releases/tag/v1.0.0
