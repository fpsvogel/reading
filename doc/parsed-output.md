<!-- omit in toc -->
# Parsed Output Guide

Hello! This is a guide to the output of the Reading gem after it parses a CSV reading log. To learn what the CSV file should look like in the first place, see the [CSV Format Guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md), relevant sections of which are linked below for convenience.

### Table of contents
- [Testing CSV strings with the `reading` command](#testing-csv-strings-with-the-reading-command)
- [Output from a minimal CSV reading log](#output-from-a-minimal-csv-reading-log)
- [The attributes](#the-attributes)
  - [`rating` attribute](#rating-attribute)
  - [`author` attribute](#author-attribute)
  - [`title` attribute](#title-attribute)
  - [`genres` attribute](#genres-attribute)
  - [`notes` attribute](#notes-attribute)
  - [`variants` attribute](#variants-attribute)
  - [`experiences` attribute](#experiences-attribute)
- [Examples](#examples)
  - [Example: book](#example-book)
  - [Example: podcast](#example-podcast)

## Testing CSV strings with the `reading` command

To quickly see the output from a CSV string, use the `reading` command:

```
$ reading '3|📕Trying|Lexpub 1970147288'
```

An optional second argument specifies enabled columns. To omit the Rating column from the example above:

```
$ reading '📕Trying|Lexpub 1970147288' 'head, sources'
```

## Output from a minimal CSV reading log

*In the CSV Format Guide: ["A minimal reading log"](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#a-minimal-reading-log)*

Here is a minimal CSV reading log:

```
\Title|Dates finished
Sapiens: A Brief History of Humankind
Tom Holt - Goatsong|2019/06/18, 2020/5/8
```

When that's parsed, the below output is produced. Comments in the first item point out all the columns from which each item attribute can possibly come from. We'll look more closely at these column-to-attribute mappings in the sections below.

```ruby
# Compare to default_config[:csv][:template] in config.rb.
# The item in the output is actually converted so that its
# Hashes become Structs for their convenient dot access,
# e.g. item.variants instead of item[:variants].
# But Hashes are easier to show in a code snippet.
parsed_items = [
  {
    rating: nil, # Rating column
    author: nil, # Head ("Title") column
    title: "Sapiens: A Brief History of Humankind", # Head
    genres: [], # Genres
    variants: [], # Head, Sources, Length
    experiences: [], # Dates Started, Dates Finished, History, Head
    notes: [], # Notes
  },
  {
    rating: nil,
    author: "Tom Holt",
    title: "Goatsong",
    genres: [],
    variants: [],
    experiences:
      [{
        spans:
          [{
            dates: ..Date.new(2019,6,18),
            progress: 1.0,
            amount: nil,
            name: nil,
            favorite?: false,
          }],
        group: nil,
        variant_index: 0,
      },
      {
        spans:
          [{
            dates: ..Date.new(2020,5,8),
            progress: 1.0,
            amount: nil,
            name: nil,
            favorite?: false,
          }],
        group: nil,
        variant_index: 0,
      }]
    notes: [],
  },
]
```

Why such verbose output for such simple CSV input? It's because the output data structure needs to be verbose in order to be able to represent more complex input, and it's convenient for the output to be *consistent*, having the same structure whether a row is simple or complex.

## The attributes

Each subsection below contains:

- Which CSV columns the attribute can possibly be parsed from, with links to the relevant sections about those columns in the CSV Format Guide.
- A slice of an output item with a particular attribute.

### `rating` attribute

CSV column: [**Rating**](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#rating-column).

```ruby
item = {
  rating: 5,
  # ...
}
```

### `author` attribute

CSV column: [**Head**](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-title).

Also specified by [compact planned items](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#compact-planned-items).

```ruby
item = {
  author: "Tom Holt",
  # ...
}
```

### `title` attribute

CSV column: [**Head**](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-title).

Also specified by [compact planned items](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#compact-planned-items).

```ruby
item = {
  title: "Goatsong",
  # ...
}
```

### `genres` attribute

CSV column: [**Genres**](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#genres-column).

Also specified by [compact planned items](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#compact-planned-items-genres).

```ruby
item = {
  genres: ["history", "fiction"],
  # ...
}
```

### `notes` attribute

CSV column: **Notes**:

- [for `content`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#notes-column)
- [for `blurb?` and `private?`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#notes-column-special-notes)

```ruby
item = {
  notes:
    [
      {
        blurb?: true,
        private?: false,
        content: "A profound meditation on the human experience.",
      },
    ],
  # ...
}
```

### `variants` attribute

*Variants* are different forms of the same item: book vs. audiobook, first vs. updated edition, and so on. The [book example below](#example-book) is a good demonstration of variants.

CSV columns:

- **Head**:
  - [for `format`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-title)
  - [for `series`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-series-and-volume)
  - [for `extra_info`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-extra-info)
- **Sources**:
  - [for `isbn`, `sources`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#sources-column)
  - [for `format`, `series`, `extra_info`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#sources-column-variants)
- [**Length**](#length-column)

Also specified by [compact planned items](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#compact-planned-items-sources).

```ruby
item = {
  variants:
    [
      {
        format: :book,
        series:
          [
            {
              name: "Macmillan Early Modern Latin",
              volume: nil,
            },
          ],
        sources:
          [
            {
              name: "Internet Archive",
              url: "https://archive.org/details/utopiaofsirthoma0000more",
            },
          ]
        isbn: "B007978NPG", # ASIN in this case
        length: 272, # pages; or e.g. "3:59" for time
        extra_info: ["trans. Ralph Robinson", "ed. H. B. Cotterill"],
      },
    ],
  # ...
}
```

### `experiences` attribute

*Experiences* are different times when you read/watched/listened to an item, such as your first time reading a book vs. your re-reading of it at a later date. For books, experiences are typically just a date started and a date finished. But if you listen to podcasts, or if you like tracking your reading in detail, then experiences are likely to become more complex. The [podcast example below](#example-podcast) demonstrates the fine-grained tracking of experiences, and explains the usefulness of the complex structure of experiences.

CSV columns:

- **Dates Started** and **Dates Finished**:
  - [for `dates`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#dates-started-and-dates-finished-columns)
  - [for `variant_index`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#dates-started-column-variants)
  - [for `progress`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#dates-started-column-progress)
  - [for `group`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#dates-started-column-group-experience)
- **Head** [for `progress`](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#head-column-dnf)
- [**History**](#history-column) for everything

```ruby
item = {
  experiences:
    [
      {
        spans:
          [
            {
              dates: Date.new(2022,12,16)..Date.new(2022,12,23),
              progress: 1.0, # i.e. 100%
              amount: 102, # pages; or e.g. "3:59" for time
              name: "Vol. 200 No. 21 (2022/12/5)",
              favorite?: false,
            },
          ],
        group: "Time Magaziners club",
        variant_index: 0,
      },
    ],
  # ...
}
```

## Examples

Now that we've seen how the reading log CSV file should be formatted, let's take a look at what output the Reading gem gives after parsing it.

In each of the two output examples below, I've copied the item template in `default_config[:csv][:template]` in [config.rb](https://github.com/fpsvogel/reading/blob/main/lib/reading/config.rb) and added to it the information that is parsed from the example. Just keep in mind that the parsed output is converted from Hashes to Structs, but the examples have Hashes because they're easier to show.

### Example: book

Here's a long but still realistic example. (Yes, I know *The Lord of the Rings* is not technically a series. I'm committing that blasphemy just for the sake of example.)

```
\Rating|Title|Sources|Dates started|Dates finished|Genres|Length|Notes|History
4|J. R. R. Tolkien - The Fellowship of the Ring -- The Lord of the Rings, #1|📕own, gift from Sam B007978NPG 480p 🔊https://archive.org/details/the-fellowship-of-the-ring_soundscape-by-phil-dragash 17:33 -- narrated by Phil Dragash|2018/05/01, 2020/12/23 v2 🤝🏼with Hannah|2018/08/10|fiction|💬A bit slow, but it really grows on you. -- The descriptions of the Shire and the appearance of Tom Bombadil are my favorite parts.
```

That would be parsed to:

```ruby
# Compare to default_config[:csv][:template] in config.rb.
# The item in the output is actually converted so that its
# Hashes become Structs for their convenient dot access,
# e.g. item.variants instead of item[:variants].
# But Hashes are easier to show in a code snippet.
parsed_items = [{
  rating: 4, #
  author: "J. R. R. Tolkien",
  title: "The Fellowship of the Ring",
  genres: ["fiction"],
  variants:
    [{
      format: :book,
      series:
        [{
          name: "The Lord of the Rings",
          volume: 1,
        }],
      sources:
        [{
          name: "own",
          url: nil,
        },
        {
          name: "gift from Sam"
          url: nil,
        }],
      isbn: "B007978NPG",
      length: 480,
      extra_info: [],
    },
    {
      format: :audiobook,
      series:
        [{
          name: "The Lord of the Rings",
          volume: 1,
        }],
      sources:
        [{
          name: "Internet Archive", # see default_config[:item][:sources][:names_from_urls]
          url: "https://archive.org/details/the-fellowship-of-the-ring_soundscape-by-phil-dragash",
        }],
      isbn: nil,
      length: "17:33",
      extra_info: ["narrated by Phil Dragash"],
    }],
  experiences:
    [{
      spans:
        [{
          dates: Date.new(2018,5,1)..Date.new(2018,8,10),
          progress: 1.0,
          amount: 480,
          name: nil,
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: Date.new(2020,12,23)..
          progress: nil,
          amount: nil,
          name: nil,
          favorite?: false,
        }],
      group: "with Hannah",
      variant_index: 1,
    }],
  notes: # Notes
    [{
      blurb?: true,
      private?: false,
      content: "A bit slow, but it really grows on you.",
    },
    {
      blurb?: false,
      private?: false,
      content: "The descriptions of the Shire and the appearance of Tom Bombadil are my favorite parts.",
    }],
}]
```

### Example: podcast

In the example above, a confusing bit that we haven't talked about yet is `spans`, inside `experiences`. What is a "span", why not put the `dates`, `amount`, and `progress` up one level in `experiences`, if in that example there's only one span to contain them anyway? And why does a span have an `amount`, when there's already a `length` up one level in `variants`?

This example will shed light on these questions. Being a podcast, it doesn't have a total length, so it has no `length` in `variants`. Instead, it defines `amount` in its `spans`, and each span represents an episode. Different episodes can of course be listened to on different days, and an episode can be DNF'ed (abandoned) partway through, which is why each span has its own `dates` and `progress`.

So it makes sense why a podcast would have all this span-based information, but why not leave this whole span business out of books, and just limit it to podcasts where it could be renamed to something more sensible like "episodes"? Because books can have spans, too, as in [the last examples of the History column in the CSV Format Guide](https://github.com/fpsvogel/reading/blob/main/doc/csv-format.md#history-pages-and-stopping-points-books). It also makes it easier on you, the user of Reading, if all items have the same structure regardless of format and mode of reading/listening/watching.

Without further ado, here's a podcast example, one that is more complex than usual just for illustration's sake:

```
\Rating|Title|Sources|Dates started|Dates finished|Genres|Length|Notes|History
3|🎤Flightless Bird||||podcast|1:00 each||2022/10/06-10/10 x8 --  -11/12 x1/week -- 11/14 0:50 ⭐#30 Leaf Blowers -- 11/15 DNF @0:15 Baseball -- x3 -- ? #32 Soft Drinks -- Christmas
```

That's parsed to the following:

```ruby
# Compare to default_config[:csv][:template] in config.rb.
# The item in the output is actually converted so that its
# Hashes become Structs for their convenient dot access,
# e.g. item.variants instead of item[:variants].
# But Hashes are easier to show in a code snippet.
parsed_items = [{
  rating: 3,
  author: nil,
  title: "Flightless Bird",
  genres: ["podcast"],
  variants:
    [{
      format: :audio,
      series: [],
      sources: [],
      isbn: nil,
      length: nil,
      extra_info: [],
    }],
  experiences:
    [{
      spans:
        [{
          dates: Date.new(2022,10,6)..Date.new(2022,10,10),
          progress: 1.0,
          amount: "8:00",
          name: nil,
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: Date.new(2022,10,11)..Date.new(2022,11,12)
          progress: 1.0,
          amount: "4:00",
          name: nil,
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: Date.new(2022,11,14)..Date.new(2022,11,14)
          progress: 1.0,
          amount: "0:50",
          name: "#30 Leaf Blowers",
          favorite?: true,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: Date.new(2022,11,15)..Date.new(2022,11,15)
          progress: 0.25,
          amount: "1:00",
          name: "Baseball",
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: Date.new(2022,11,15)..Date.new(2022,11,15)
          progress: 1.0,
          amount: "3:00",
          name: nil,
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: nil
          progress: nil,
          amount: "1:00",
          name: "#32 Soft Drinks",
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    },
    {
      spans:
        [{
          dates: nil
          progress: nil,
          amount: "1:00",
          name: "Christmas",
          favorite?: false,
        }],
      group: nil,
      variant_index: 0,
    }],
  notes: [],
}]
```
