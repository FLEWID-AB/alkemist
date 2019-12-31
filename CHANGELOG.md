# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `Alkemist.Assigns.Index` to encapsulate assigns for index view
- `Alkemist.Assigns.Show` to encapsulate assigns for show view
- `Alkemist.Assigns.Form` to encapsulate assigns for form views (new, edit)
- `Alkemist.Assigns.Global` to provide logic for global assigns (all views)

### Changed
- Introduced types for columns and scopes and actions, see `Alkemist.Types.Column`,`Alkemist.Types.Scope` and `Alkemist.Types.Action`

### Deprecated
- `Alkemist.Assign.index/3` is now deprecated in favor of `Alkemist.Assign.Index.assigns/3`
- `Alkemist.Assign.show/2` is now deprecated in favor of `Alkemist.Assign.Show.assigns/2`
- `Alkemist.Assign.form/2` is now deprecated in favor of `Alkemist.Assign.Form.assigns/2`

### Removed
- Menu Registry - TODO: write details