## [0.2.4] - 2021-10-08

- Renamed the `article` default format to `piece`, and changed its emoji.
- Fixed a bug where custom formats were not being incorporated into the regex config.

## [0.2.2] - 2021-10-06

- Added the ability to omit the last parsed item from the list when `:skip` is returned from `selective_continue`.

## [0.2.1] - 2021-10-05

- Fixed the default value of `config[:errors][:max_length]` so that it does not rely on "io/console".

## [0.2.0] - 2021-09-26

- Added "experiences" and "variants" which allow for more sophisticated tracking of re-readings.
- Added custom columns.
- Added compact planned item lists.
- Heavily refactored and rewrote tests from scratch.
- All this was to make reading-csv ready for use in [Plain Reading](https://github.com/fpsvogel/plainreading).

## [0.1.0] - 2021-06-22

- Initial release (under the old name "reading-csv-load", now yanked from RubyGems)
