## [0.7.0] - upcoming

- Add parsing of the History column.

## [0.6.0] - upcoming

- Improved the docs.
  - Expanded the CSV Format Guide.
  - Added a Parsed Item Guide.
- Changed `CSV#parse` to return Structs instead of Hashes, for more convenient dot access.
- Added a `reading` executable for testing CSV lines.
- Changes to output structure and default values:
  - Added a question mark to the end of two `note` sub-attributes: `#private?` and `#blurb?`.
  - Moved `progress` from `experiences` down into `spans`.
  - Moved `series` down into `variants`.
  - Made `progress` default to `1.0` for `spans` with an end date.
  - Made `amount` default to `length`.
- Simplified the Source column by removing custom URL names.
- Added features to compact planned rows:
  - Single-item compact planned rows (optionally with Sources column).
  - Naming a source at the beginning of the row.
  - Multiple genres at the beginning of the row.
  - Certain config-defined emojis are ignored.

## [0.5.0] - 2022-12-18

- Added docs.
- Added date validations.
- Parse each date string into a `Date`.
- Removed unused features: date added, visibility, multiple format emojis in compact planned items.
- Removed two little-used columns, Blurb and Private Notes, making them specially-marked Notes instead. Notes are now structured as an array of hashes rather than a simple array of strings.

## [0.4.0] - 2022-11-22

- Renamed to Reading.
- Removed dependency on ActiveSupport.
- High-level cleanup/refactor.

## [0.3.0] - 2022-05-10

- Added configurable default values for custom columns.
- Multiple format emojis allowed in compact planned items.

## [0.2.4] - 2021-10-08

- ActiveSupport 7 allowed.

## [0.2.3] - 2021-10-08

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
- All this was to make Reading ready for use in [Plain Reading](https://github.com/fpsvogel/plainreading).

## [0.1.0] - 2021-06-22

- Initial release (under the old name "reading-csv-load", now yanked from RubyGems)
