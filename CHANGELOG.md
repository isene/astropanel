# Changelog

All notable changes to AstroPanel will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.0] - 2025-10-26

### Added
- Modern image display using termpix gem with multi-protocol support
- Sixel protocol support for compatible terminals (mlterm, xterm, foot)
- Automatic protocol detection and fallback

### Changed
- Refactored image display to use termpix gem instead of direct w3m calls
- Cleaner, more maintainable code (~45 lines reduced to ~25)

### Fixed
- Image clearing now prevents overlapping when switching between starchart and APOD
- Proper height calculation to avoid cutting into bottom pane

## [4.0.0] - 2025-10-25

### Breaking Changes
- Requires rcurses 6.0.0+ with explicit initialization for Ruby 3.4+ compatibility

## [3.0.0] - Previous release

### Changed
- Major accuracy improvement with IAU 2006 obliquity standard
