<h1 align="center">Reading</h1>

Reading is a Ruby gem that parses a CSV reading log. [My personal site's Reading page](https://fpsvogel.com/reading/) is built with the help of this gem.

### Table of Contents

- [Why?](#why)
- [Installation](#installation)
- [Docs](#docs)
- [Usage](#usage)
  - [Try out a CSV string](#try-out-a-csv-string)
  - [Parse a file](#parse-a-file)
  - [Custom config](#custom-config)
- [How to add a reading page to your site](#how-to-add-a-reading-page-to-your-site)
- [Contributing](#contributing)
- [License](#license)

## Why?

Because I love reading, and keeping a plain-text reading log helps me remember, reflect on, and plan my reading (and listening, and watching).

My CSV reading log serves the same role as Goodreads used to, but it lets me do a few things that Goodreads doesn't:

- Add items of any format: podcasts, documentaries, etc.
- Own my data.
- Edit and search in a plain text file, which is faster than navigating a site or app. I can even pull up my reading log on my phone via a Dropbox-syncing text editor app—[Simple Text](https://play.google.com/store/apps/details?id=simple.text.dropbox) is the one I use.
- Get the features I need by adding them myself, instead of wishing and waiting for the perfect Goodreads-esque service. For example, when I started listening to more podcasts, I added automatic progress tracking based on episode length and frequency, so that I didn't have to count episodes and sum up hours.

So a CSV reading log is great, but there's one problem: how to share it with friends? No one wants to wade through a massive CSV file.

That's where this gem helps: it transforms my `reading.csv` into data that I can selectively display on a page on my site.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reading'
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

### Try out a CSV string

To quickly see the output from a CSV string, use the `reading` command:

```
$ reading '3|📕Trying|Little Library 1970147288'
```

The pipe character (`|`) is the column separator. The above example includes the first three columns (Rating, Head, and Sources) which contain a rating, format (book), title, source, and ISBN. You'll see all those reflected in the parsed data that is output to the console after you run the command.

An optional second argument specifies enabled columns. To omit the Rating column from the example above:

```
$ reading '📕Trying|Little Library 1970147288' 'head, sources'
```

To see the parser output from a file (e.g. to see if it is correctly formatted), use the `readingfile` command:

```
$ readingfile /home/alex/reading.csv
```

### Parse a file

To parse a CSV reading log:

```ruby
require "reading"

file_path = "/home/user/reading.csv"
items = Reading.parse(file_path)
```

This returns an array of Structs, each representing an item (such as a book or podcast) structured like the template hash in `Config#default_config[:item_template]` in [config.rb](https://github.com/fpsvogel/reading/blob/main/lib/reading/config.rb).

If instead of a file path you want to directly parse a string (or anything else responding to `#each_line`):

```ruby
require "reading"

string = File.read(file_path)
items = Reading.parse(string: string)
```

### Custom config

To use custom configuration, pass a config hash when initializing.

Here's an example. If you don't want to use all the columns (as in [the minimal example in the CSV format guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#a-minimal-reading-log)), you'll need to initialize a `Reading::CSV` with a config including only the desired columns, like this:

```ruby
require "reading"

custom_config = { enabled_columns: [:head, :end_dates] }
file_path = "/home/user/reading.csv"
items = Reading.parse(file_path, config: custom_config)
```

## How to add a reading page to your site

After Reading parses your CSV reading log, it's up to you to display that parsed information on a web page. I've set up my personal site so that it automatically parses my reading log during site generation, and it's even automatically generated every week. That means my site's Reading page automatically syncs to my reading log on a weekly basis.

I explain how I did this in my tutorial ["Build a blog with Bridgetown"](https://fpsvogel.com/posts/2021/build-a-blog-with-bridgetown), which may give you ideas even if you don't use [Bridgetown](https://www.bridgetownrb.com/) to build your site… but you should use Bridgetown, it's great 😉

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fpsvogel/reading.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
