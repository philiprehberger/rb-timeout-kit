# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-17

### Added
- `Deadline#elapsed` returns seconds since the deadline was created (complement to `#remaining`)

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-29

### Added
- Deadline callbacks via `on_expire:` keyword argument or `Deadline#on_expire` block registration, fired once on first expiry detection
- Grace period via `grace:` keyword argument with `Deadline#in_grace?` and `Deadline#grace_remaining` accessors
- Deadline naming via `name:` keyword argument with `Deadline#name` accessor, included in error messages
- Full README compliance with 8 badges, Support section, and all standard sections
- GitHub issue templates (bug report, feature request), dependabot config, and PR template

## [0.1.1] - 2026-03-22

### Added
- Expanded test suite from 19 to 30+ examples covering edge cases, error hierarchy, zero/large timeouts, nested deadlines, and cooperative timeout loops

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Cooperative deadline with nested support and remaining time tracking
- Cooperative timeout with explicit cancellation checks
- DeadlineExceeded error for expired deadlines
- Thread-local deadline stack for nested contexts
