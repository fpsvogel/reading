# Reading::Csv

Reading::Csv parses a CSV reading list into an array of Ruby hashes containing the data of the books and other items listed in the CSV file. [The Plain Reading app](https://plainreading.herokuapp.com) serves as a web interface for Reading::Csv.

## Usage

The most basic usage is to parse a CSV reading list with the default configuration. See Documentation below to learn all about the expected format of the CSV file.

```ruby
items_hashes = Reading::Csv::Parse.new.call(file_path)
```

More advanced usage can be found in [`test/csv_parse_test.rb`](https://github.com/fpsvogel/reading-csv/blob/main/test/csv_parse_test.rb) or in [the List model](https://github.com/fpsvogel/plainreading/blob/main/app/models/list.rb) in Plain Reading, a Rails app that uses Reading::Csv.

## Documentation

[The Plain Reading Guide](https://plainreading.herokuapp.com/guide) is a good introduction to Reading::Csv as it is the parser behind Plain Reading. If you prefer looking at tests, see [`test/csv_parse_test.rb`](https://github.com/fpsvogel/reading-csv/blob/main/test/csv_parse_test.rb).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "reading-csv"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install reading-csv

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fpsvogel/reading-csv.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
