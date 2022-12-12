<h1 align="center">Reading</h1>

Reading parses a CSV reading list into an array of Ruby hashes containing the data of items (such as books) listed in the CSV file. [My personal site's Reading page](https://fpsvogel.com/reading/) is built using this gem.

### Table of Contents

- [Why am I building this?](#why-am-i-building-this)
- [Installation](#installation)
- [Usage](#usage)
- [CSV documentation](#csv-documentation)
- [Contributing](#contributing)
- [License](#license)

## Why am I building this?

Because I love reading and keeping track of my reading, but I don't love the limitations of Goodreads and other social reading sites. In particular:

- I don't like going into a site or app every time I want to make a small change such as adding a note. I find it much faster to edit a plain text file which I always have open on my computer.
- I don't like being limited to a database of existing book metadata. In Goodreads I could add new titles to their database, but that is cumbersome. Plus, it's nice to be able to track items other than books.
- On Goodreads and similar sites, my reading data is theirs, not mine. I could get my data by exporting it as a CSV file, but then the formatting of the file is terrible because it's full of junk columns that I don't want.

These considerations led me to start tracking my reading and notes directly in a CSV file. Then a problem arose: how to share my reading list with friends? I'm sure they wouldn't want to wade through my massive CSV file, and anyway I have some items and notes in there that I don't want everyone to see.

That's where Reading helps: it transforms my `reading.csv` into a page on my site.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "reading"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install reading

## Usage

The most basic usage is simply to specify the path to your CSV reading list, and it will be parsed with the default configuration. See [CSV documentation](#csv-documentation) below to learn about the expected format of the CSV file.

```ruby
file_path = "/home/jo/reading.csv"
csv = Reading::CSV.new(path: file_path)
items_hashes = csv.parse
```

This returns an array of hashes, each representing an item (such as a book or podcast) structured like the template hash in `default_config[:item][:template]` in [config.rb](https://github.com/fpsvogel/reading/blob/main/lib/reading/config.rb).

If instead of a file path you want to directly parse a string or file (anything responding to `#each_line`):

```ruby
csv_string_or_file = File.read(file_path)
csv = Reading::CSV.new(csv_string_or_file)
items_hashes = csv.parse
```

To use custom configuration, pass a config hash when initializing:

```ruby
custom_config = { csv: { skip_compact_planned: true } }
csv = Reading::CSV.new(path: file_path, config: custom_config)
items_hashes = csv.parse
```

## CSV documentation

The [CSV format guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format-guide.rb) shows by example how to set up a CSV reading log of your own. If you prefer looking at tests, see [`test/csv_parse_test.rb`](https://github.com/fpsvogel/reading/blob/main/test/csv_parse_test.rb).

The parsing features are documented more comprehensively in [`test/csv_parse_test.rb`](https://github.com/fpsvogel/reading/blob/main/test/csv_parse_test.rb).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fpsvogel/reading.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
