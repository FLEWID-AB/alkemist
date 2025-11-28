# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Fixed deprecation warning for `map.field` notation without parentheses in `lib/alkemist/assign.ex:290` and `lib/alkemist/assign.ex:292`. Changed `resource.__struct__` to `resource.__struct__()` to comply with modern Elixir syntax requirements.
- Fixed "column does not exist" error when using `_ilike` and `_not_ilike` operator suffixes in search parameters. Added support for these operators in the regex patterns in `lib/alkemist/query/search.ex:205` and `lib/alkemist/query/search.ex:347`, and added the corresponding operator mappings to `map_turbo_operator_to_flop/1` function.
