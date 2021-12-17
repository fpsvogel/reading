<h1 align="center">Reading::Csv</h1>

Reading::Csv parses a CSV reading list into an array of Ruby hashes containing the data of the books and other items listed in the CSV file. My [Plain Reading app](https://plainreading.herokuapp.com) serves as a web interface for Reading::Csv. [My personal site's Reading page](https://fpsvogel.com/reading/) is also built using this gem.

### Table of Contents

- [Why this on my GitHub portfolio](#why-this-on-my-github-portfolio)
- [Usage](#usage)
- [Documentation](#documentation)
- [Installation](#installation)
- [Contributing](#contributing)
- [License](#license)

## Why this on my GitHub portfolio

This gem is the foundation of my reading list projects. These are my most ambitious effort, and part of that is due to the complexity of parsing the CSV reading list in a flexible enough way to accommodate a wide range of reading-tracking habits, from minimal to very detailed. You can get a taste of this flexibility in [the guide at Plain Reading](https://plainreading.herokuapp.com/guide), which shows the many possible formats of the CSV reading list. I achieved this flexibility by using [a bit of metaprogramming](https://github.com/fpsvogel/reading-csv/blob/57df9ab5bb7427910fea29fada60613ee52fe8b3/lib/reading/csv/parse_regular_line.rb#L34), which allows [even custom CSV columns](https://github.com/fpsvogel/reading-csv/blob/57df9ab5bb7427910fea29fada60613ee52fe8b3/lib/reading/csv/parse_regular_line.rb#L41) to be defined.

I also put a lot of work into testing the gem, so that [`test/csv_parse_test.rb`](https://github.com/fpsvogel/reading-csv/blob/main/test/csv_parse_test.rb) serves as excellent documentation of the parser's features, besides making the development of added features so much faster because I can immediately catch and fix bugs even in very remote edge cases, because I try to include all possible CSV configurations in the test cases.

## Usage

The most basic usage is to parse a CSV reading list with the default configuration. See Documentation below to learn all about the expected format of the CSV file.

```ruby
items_hashes = Reading::Csv::Parse.new.call(file_path)
```

More advanced usage can be found in [`test/csv_parse_test.rb`](https://github.com/fpsvogel/reading-csv/blob/57df9ab5bb7427910fea29fada60613ee52fe8b3/test/csv_parse_test.rb#L773) or in [the List model](https://github.com/fpsvogel/plainreading/blob/968b53bfe44bb3a1dea0033bae68504cbe1df289/app/models/list.rb#L39) in Plain Reading, a Rails app that uses Reading::Csv.

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
