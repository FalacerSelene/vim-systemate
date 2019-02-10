Changelog
=========

All notable changes to this project will be documented in this file.

This file's format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/). The
version number is tracked in the file `addon-info.json`.

[unreleased]
------------

### Changed
- Autoapply settings now live under `g:systemate_autoapply`, rather than under
  `g:systemate.{style}.auto_apply`.
- Autoapply `pc_name_match` key changed to be named `hostname`. Semantics are
  the same.
- Autoapply `for_filetypes` key changed to be named `filetypes`. Semantics are
  the same.

### Added
- Autoapply key `priority`. This integer key determines in which order the
  various autoapply settings are considered. By default 0. Two settings with
  the same priority are considered in an indeterminate order.
- Now provides a decent amount of documentation. Still not complete though.

### Fixed
- Now correctly autoapplies settings at start of day.
- Fixed a bug with reverting settings which are not strings.

[0.1.0]
-------

### Added
- First implementation

[unreleased]: https://www.github.com/FalacerSelene/vim-systemate
[0.1.0]: https://www.github.com/FalacerSelene/vim-systemate/tree/0.1.0
