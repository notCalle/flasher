# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added

- Command line option to decompress an image while writing [FIXME: not yet implemented]


## [1.2.3] - 2021-06-12

### Changed

- Refactored as a Swift package, and switch to using public dependencies, instead of abusing Swift Package Manager internals.
- Refactored internal I/O responsibilities for improved async performance.

### Fixed

- Memory usage bloat by the size of the image file during the verification phase.
- Crash when input file size was not a multiple of the output device block size.

## [1.2.2] - 2019-10-15

This fixes issues with safe media detection.

### Changed

- Raises the media size safe-guard, allowing devices smaller than 256 GiB.

### Fixed

- `Internal` devices that are removable were incorrectly rejected.


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


[Unreleased]: https://github.com/notCalle/flasher/compare/v1.2.3...HEAD
[1.2.3]: https://github.com/notCalle/flasher/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/notCalle/flasher/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/notCalle/flasher/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/notCalle/flasher/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/notCalle/flasher/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/notCalle/flasher/releases/tag/v1.0.0
