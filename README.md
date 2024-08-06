<h1 align="center">Reading</h1>

Reading is a Ruby gem that parses a CSV reading log. My personal site's [Reading List](https://fpsvogel.com/reading/) and [Reading Statistics](https://fpsvogel.com/reading-stats/) pages are built with the help of this gem.

### Table of Contents

- [Why?](#why)
- [Installation](#installation)
- [Docs](#docs)
- [Usage](#usage)
  - [Try out a CSV string](#try-out-a-csv-string)
  - [Parse in Ruby](#parse-in-ruby)
  - [Parse with custom config](#parse-with-custom-config)
  - [Filtering the output](#filtering-the-output)
  - [Get statistics on your reading](#get-statistics-on-your-reading)
- [How to add a reading page to your site](#how-to-add-a-reading-page-to-your-site)
- [Contributing](#contributing)
- [License](#license)

## Why?

Because I love reading, and keeping a plain-text reading log helps me remember, reflect on, and plan my reading (and listening, and watching).

My CSV reading log serves the same role as Goodreads used to, but it lets me do a few things that Goodreads doesn't:

- Own my data.
- Add items of any format: podcasts, documentaries, etc.
- Edit and search in a plain text file, which I prefer over navigating a site or app. I can even pull up my reading log on my phone via a Dropbox-syncing text editor app—[Simple Text](https://play.google.com/store/apps/details?id=simple.text.dropbox) is the one I use.

This gem solves the biggest problem I had with a plain-text reading log: **how to share my favorite reads with friends?** The gem's parser transforms my `reading.csv` into data that I can selectively display on [my Reading List page](https://fpsvogel.com/reading/).

The Reading gem also gives statistics data, exemplified on [my Reading Statistics page](https://fpsvogel.com/reading-stats/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "reading"
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install reading
```

## Docs

[CSV Format Guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md) on how to set up your own CSV reading log.

[Parsed Output Guide](https://github.com/fpsvogel/reading/blob/main/doc/parsed-output.md) on the structure into which the Reading gem parses CSV rows.

[`test/parse_test.rb`](https://github.com/fpsvogel/reading/blob/main/test/parse_test.rb) has more examples of the CSV format.

## Usage

For examples of real-life usage, see [the LoadReadingList plugin](https://github.com/fpsvogel/fpsvogel.com/blob/main/plugins/builders/load_reading_list.rb) on my website, which gets my `reading.csv` from Dropbox and parses it. The parsed items are used on two pages:

- [fpsvogel.com/reading](https://fpsvogel.com/reading/): [source](https://github.com/fpsvogel/fpsvogel.com/blob/main/src/reading_list.md) plus [view component source](https://github.com/fpsvogel/fpsvogel.com/tree/main/src/_components).
- [fpsvogel.com/reading-stats](https://fpsvogel.com/reading-stats/): [source](https://github.com/fpsvogel/fpsvogel.com/blob/main/src/reading_stats.md).

### Try out a CSV string

To quickly see the parsed output from a CSV string, use the `reading` command:

```
$ reading '3|📕Trying|Little Library 1970147288'
```

See the [CSV Format Guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md) for more on columns, but here suffice it to note that this CSV string has the first three columns (Rating, Head, and Sources).

An optional second argument specifies enabled columns. The CSV string above already omits several right-side columns, but to omit a left-side or middle column we'll have to disable it. For example, to omit the Rating column from the example above:

```
$ reading '📕Trying|Little Library 1970147288' 'head, sources'
```

The `reading` command can also start a prompt to query for reading statistics. For more on that, see ["Get statistics on your reading"](#get-statistics-on-your-reading) below.

### Parse in Ruby

To parse a CSV reading log in Ruby rather than on the command line:

```ruby
require "reading"

file_path = "/home/user/reading.csv"
items = Reading.parse(path: file_path)
```

This returns an array of [Items](https://github.com/fpsvogel/reading/blob/main/lib/reading/item.rb), which are essentially a wrapper with the same structure as the template Hash in `Config#default_config[:item][:template]` in [config.rb](https://github.com/fpsvogel/reading/blob/main/lib/reading/config.rb), but providing a few conveniences such as dot access (`item.notes` instead of `item[:notes]`).

If instead of a file path you want to directly parse a String (or anything else responding to `#each_line`, such as a `File`):

```ruby
require "reading"

csv_string = '3|📕Trying|Little Library 1970147288'
items = Reading.parse(lines: csv_string)
```

### Parse with custom config

To use custom configuration, pass a config Hash when initializing.

Here's an example. If you don't want to use all the columns (as in [the minimal example in the CSV format guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#a-minimal-reading-log)), you'll need to pass in a config including only the desired columns, like this:

```ruby
require "reading"

custom_config = { enabled_columns: [:head, :end_dates] }
file_path = "/home/user/reading.csv"
items = Reading.parse(path: file_path, config: custom_config)
```

### Filtering the output

Once you've parsed your reading log, you can easily filter the output like this:

```ruby
# ...
# (Already parsed a reading log into `items` as above.)
filtered_items = Reading.filter(
  items: items,
  minimum_rating: 4,
  status: [:done, :in_progress],
  excluded_genres: ["cats", "memoir"],
)
```

### Get statistics on your reading

The `reading` command can also start an interactive statistics-querying mode if the command is given the path to a CSV file:

```
$ reading /home/user/reading.csv
```

Then a prompt will appear, in which you can type commands made up of an **operation** optionally followed by one or more **groupings** and/or one or more **filters**.

Here are a few examples:

```
average rating
total amount by month
total items by year, genre
top 5 lengths status!=planned format=print, ebook
top 3 amounts by year rating>1 done<100% source~library
```

> **Warning**
> The operation, grouping, and filter(s) *must* appear in that order, or else the query may yield unexpected results.

You can also get statistics via Ruby code rather than on the command line:

```ruby
# ...
# (Already parsed a reading log into `items` as above.)
results = Reading.stats(
  input: "total amount by month"
  items: items,
)
```

<!-- omit in toc -->
#### Stats operations

The last word may be pluralized.

- `average rating`
- `average length`
- `average amount`
- `average daily-amount`
- `list items` (or just `list`)
- `total items` (or just `items`, or `count`)
- `total amount` (or just `amount`)
- `top/bottom [N] ratings`
- `top/bottom [N] lengths`
- `top/bottom [N] amounts`
- `top/bottom [N] speeds`
- `debug` to view the results in a Ruby debugger

<!-- omit in toc -->
#### Stats groupings

These too may be pluralized.

- `by month`
- `by year`
- `by eachgenre` (single genres)
- `by genre` (combinations of genres)
- `by rating`
- `by format`
- `by source`
- `by length`

<!-- omit in toc -->
#### Stats filters

These may be pluralized, and may be followed by any of the operators listed for each. The operators `~` and `!~` mean "contains" and "does not contain", respectively.

- `genre` (`=`, `!=`)
- `rating` (`=`, `>`, `>=`, `<`, `<=`, `!=`)
- `format` (`=`, `!=`)
- `source` (`=`, `!=`, `~`, `!~`)
- `title` (`=`, `!=`, `~`, `!~`)
- `author` (`=`, `!=`, `~`, `!~`)
- `series` (`=`, `!=`, `~`, `!~`)
- `note` (`=`, `!=`, `~`, `!~`)
- `status` (`=`, `!=`)
- `length` (`=`, `>`, `>=`, `<`, `<=`, `!=`)
- `done` (`=`, `>`, `>=`, `<`, `<=`, `!=`)
- `experiences` (i.e. number of reads) (`=`, `>`, `>=`, `<`, `<=`, `!=`)
- `date` (`=`, `>`, `>=`, `<`, `<=`, `!=`)
- `end-date` (`=`, `>`, `>=`, `<`, `<=`, `!=`)

## How to add a reading page to your site

After Reading parses your CSV reading log, it's up to you to display that parsed information on a web page. I've set up my personal site so that it parses my reading log during site generation, and it's even automatically generated every week. That means my site's "Reading" page automatically syncs to my reading log on a weekly basis.

I explain how I did this in my tutorial ["Build a blog with Bridgetown"](https://fpsvogel.com/posts/2021/build-a-blog-with-bridgetown), which may give you ideas even if you don't use [Bridgetown](https://www.bridgetownrb.com/) to build your site… but you should use Bridgetown, it's great 😉

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fpsvogel/reading.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
