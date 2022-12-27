<!-- omit in toc -->
# CSV Format Guide

Welcome! This is a guide to setting up your own CSV reading log to be parsed by the Reading gem. If you want the quickest start possible, download and edit [the reading.csv template](https://github.com/fpsvogel/reading/blob/main/doc/reading.csv) and refer to the sections below as needed. Then see [next steps](#next-steps) below.

This guide is written to show you what your reading log CSV file should look like in order for it to be parsable. What the data looks like *after* it's parsed is covered separately in the [parsed output guide](https://github.com/fpsvogel/reading/blob/main/doc/parsed-output.md).

### Table of contents
- [Preliminaries: how to edit a CSV file pleasantly](#preliminaries-how-to-edit-a-csv-file-pleasantly)
- [A minimal reading log](#a-minimal-reading-log)
- [Basics](#basics)
  - [Rating column](#rating-column)
  - [Head column ("Title")](#head-column-title)
  - [Sources column](#sources-column)
  - [Dates Started and Dates Finished columns](#dates-started-and-dates-finished-columns)
  - [Genres column](#genres-column)
  - [Length column](#length-column)
  - [Notes column](#notes-column)
- [Planned items](#planned-items)
  - [Compact planned items: genres](#compact-planned-items-genres)
  - [Compact planned items: sources](#compact-planned-items-sources)
  - [Compact planned items: ignored emojis](#compact-planned-items-ignored-emojis)
- [Advanced](#advanced)
  - [Head column: DNF](#head-column-dnf)
  - [Head column: series and volume](#head-column-series-and-volume)
  - [Head column: extra info](#head-column-extra-info)
  - [Head column: multiple items](#head-column-multiple-items)
  - [Sources column: variants](#sources-column-variants)
  - [Dates Started column: variants](#dates-started-column-variants)
  - [Dates Started column: progress](#dates-started-column-progress)
  - [Dates Started column: group experience](#dates-started-column-group-experience)
  - [Notes column: special notes](#notes-column-special-notes)
  - [History column](#history-column)
    - [History: regular item (podcast)](#history-regular-item-podcast)
    - [History: occasional item (podcast)](#history-occasional-item-podcast)
    - [History: planned and DNF (podcast)](#history-planned-and-dnf-podcast)
    - [History: no names and re-watching (TV show)](#history-no-names-and-re-watching-tv-show)
    - [History: pages and stopping points (books)](#history-pages-and-stopping-points-books)
- [Next steps](#next-steps)

## Preliminaries: how to edit a CSV file pleasantly

- I highly recommend the [Rainbow CSV](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv) for VS Code. It's perfect for editing CSV files with potentially long columns, as your reading log is likely to have.
- Entering a row is much less cumbersome if you set up keyboard shortcuts for a row template and for today's date. I myself use [an AutoHotkey script](https://github.com/fpsvogel/reading/blob/main/doc/autohotkey-reading-csv.rb) for this.

## A minimal reading log

Here is the beginning of a minimal CSV reading log:

```
\Title|Dates finished
Sapiens: A Brief History of Humankind
Tom Holt - Goatsong|2019/06/18, 2020/5/8
```

- The first line (containing headers) is a comment because it starts with a backslash (`\`). Comments are ignored by the parser. The header comment is not special; you can put whatever you want in it, or you can omit it altogether.
- Then we have two items, books in this case.
- Columns are divided by a pipe character (`|`).
- This means you *must not* use the pipe character anywhere except to divide columns (or in comments).
- Empty columns on the right side may be omitted, as in the first item.
- The author is optional, too. The only thing every row must have is the title.
- To sum up these two rows: you haven't read *Sapiens* yet, and you've read *Goatsong* twice. Nice!

If this minimal kind of reading log is what you want, see example in the ["Custom config"](https://github.com/fpsvogel/reading/blob/main/README.md#custom-config) section of the README.

You could go even more minimalist and disable the Dates Finished column if you just want to keep a list of books you've read. (But in that case, why not just use a text file?)

By default, all columns are enabled. We'll learn about each column in turn, but first here are those same two items but now with all columns, so that you can get an idea of what a full item looks like. Here's a screenshot from VS Code using the above-mentioned Rainbow CSV extension:

![example reading log in Rainbow CSV](/rainbow-csv-example.png)

And here are those same rows in a code snippet:

```
\Rating|Title|Sources|Dates started|Dates finished|Genres|Length|Notes|History
|🔊Sapiens: A Brief History of Humankind|Hoopla B00ICN066A|2021/09/20||history, wisdom|15:17|Easy to criticize, but I like the emphasis on human happiness. -- Ch. 5: "We did not domesticate wheat. It domesticated us." -- Discussion of that point: https://www.reddit.com/r/AskHistorians/comments/2ttpn2
5|50% 📕Tom Holt - Goatsong|Lexpub 0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247
```

Remember, you don't *have* to fill in every column every time, and the title is the only thing that's required on every line. Everything else is optional.

Now, onto the columns!

## Basics

Here are the features of each column that you'll most often use. To keep the examples below as concise as possible, not all the columns will be shown at once.

### Rating column

The Rating column can be any number. Your rating scale is up to you.

```
\Rating|Title
3.5|Hamlet
5|Cosmos
|Utopia
9001|Goku's Power Level
```

### Head column ("Title")

The second column is the Head column, which here has the header "Title", but it actually can contain a lot of information. Let's start with the format, author, and title:

```
\Title
Hamlet
Carl Sagan - Cosmos
📕Utopia
🔊R. J. Palacio - Wonder
```

Only the title is always required. The format and author are optional.

These are the formats and their corresponding emojis, defined in [config.rb](https://github.com/fpsvogel/reading/blob/main/lib/reading/config.rb):

Format     |Emoji
-----------|-----
`print`    |📕
`ebook`    |⚡
`audiobook`|🔊
`pdf`      |📄
`audio`    |🎤
`video`    |🎞️
`course`   |🏫
`piece`    |✏️
`website`  |🌐

You can define your own formats via a custom config, similar to the example in the ["Custom config"](https://github.com/fpsvogel/reading/blob/main/README.md#custom-config) section of the README.

### Sources column

The Sources column is for a few different pieces of information. Here are a few things it can include.

An ISBN-10, ISBN-13, or ASIN number:

```
\Title|Sources
Hamlet|0141396504
Cosmos|978-0345539434
Utopia|B078Y97W7D
```

The source where you got the item. This can be either a name or a URL:

```
\Title|Sources
Hamlet|Lexington Public Library
Utopia|https://www.gutenberg.org/ebooks/2130
```

And you can mix them together, one number plus one or more sources:

```
\Title|Sources
Hamlet|Lexington Public Library 0141396504
Cosmos|Hoopla 978-0345539434 recommended by Sam
Utopia|B078Y97W7D https://www.gutenberg.org/ebooks/2130
```

If two name sources are adjacent, separate them with commas:

```
\Title|Sources
Cosmos|Hoopla, recommended by Sam 978-0345539434
```

### Dates Started and Dates Finished columns

These two columns can be used separately (you can disable one or the other), but they're similar so let's look at both.

Dates must be in the format `yyyy/mm/dd`, with zeroes either included or omitted:

```
\Title|Dates started|Dates finished
Hamlet|2020/05/01|2020/5/9
```

Use commas to separate multiple dates, with the earlier dates on the left side:

```
\Title|Dates started|Dates finished
Cosmos|2019/11/22, 2020/07/17, 2022/10/05|2019/12/10, 2020/08/15
```

The above example means that you started and finished the book in 2019 and again in 2020. In 2022 you've started it but haven't yet finished it (since there isn't a third date finished to match that date started).

The examples above are done and in progress, respectively, but what about a *planned* item, something on your "to read" list? Just omit the dates entirely:

```
\Title|Dates started|Dates finished
Utopia
```

### Genres column

Genres are just a list, all in lowercase:

```
\Title|Genres
Hamlet|classic, elizabethan drama
Cosmos|science, astronomy, classic|
Utopia|latin
```

### Length column

A length can be a whole number (for pages) or in `hh:mm` format for time:

```
\Title|Length
Hamlet|400
Cosmos|14:07
```

### Notes column

Notes are separated by ` -- ` (two hyphens surrounded by spaces):

```
\Title|Notes
Hamlet|In contemporary English: https://nosweatshakespeare.com/plays/modern-hamlet -- I.2: Claudius' speech full of contradictory images. -- I.3: Laertes' speech to Ophelia is creepy…
```

## Planned items

A.k.a. your "to read" list. We'll circle back to the columns to show their advanced features, but first: how to jot down books that you might read in the future?

One way to track this is to have normal items, but without a date started.

```
\Rating|Title|Sources|Dates started|Dates finished|Genres|Length|Notes|History
\------ PLANNED
|📕Beloved||||fiction, history
|🔊Kindred||||fiction, history
```

### Compact planned items: genres

But if you use all the columns (as in the above example), then this is quite verbose for keeping track of books that you just *might* read. Here is a quicker and more compact way to jot down planned items:

```
\------ PLANNED
\FICTION, HISTORY: 📕Beloved 🔊Kindred
```

There are two requirements for a compact planned item to be parsed:

- The line *must* start with a comment character (`\`).
- The format emoji *must* be present.

The genres are optional, but they're included they *must be in all-caps*. The all-caps genres are changed to lowercase by the parser. So the items in the example above will have the genres "fiction" and "history".

Or you can omit genres, and the planned items will still be parsed. This is handy if you want to quickly save an individual title on its own line which you'll start reading soon:

```
\📕Beloved
\🔊Kindred
```

### Compact planned items: sources

You can include one or more sources after the title, each preceded by `@`:

```
\📕Beloved @Lexpub @Jeffco
\🔊Kindred @Lexpub
```

You can group the items with one or more common sources:

```
\@Lexpub: 📕Beloved @Jeffco 🔊Kindred
```

Or with genres and source:

```
\HISTORY, FICTION @Lexpub: 📕Beloved @Jeffco 🔊Kindred
```

### Compact planned items: ignored emojis

In a row of compact planned items, certain emojis are ignored. For the default list, see `default_config[:csv][:compact_planned_ignored]` in [config.rb](https://github.com/fpsvogel/reading/blob/main/lib/reading/config.rb).

This makes it easier to manage lists of planned items using emojis as visual markers. Here's an example which produces the exact same output as the previous example, because the extra emojis (`❓`, `💲`, and `⏳`) are ignored:

```
\❓HISTORY, FICTION @Lexpub: 📕Beloved ⏳@Jeffco 💲🔊Kindred
```

## Advanced

### Head column: DNF

Quitting a book partway through is an underappreciated art. In these cases, you can put `DNF` at the beginning of the Head column (*before* the format, if any), optionally followed by a stopping point:

```
\Title|Length
DNF 📕Wonder|368
DNF 23% 📕Hamlet|400
DNF 3:40 🔊Cosmos|14:07
DNF p105 📕Utopia|336
```

What the parser actually understands from `DNF <amount>` is simply the amount of progress made, with a bare `DNF` defaulting to no progress. Progress can also be indicated with amounts on their own, so the following examples give the exact same output as the above:

```
\Title|Length
0% 📕Wonder|368
23% 📕Hamlet|400
3:40 🔊Cosmos|14:07
p105 📕Utopia|336
```

So `DNF` is just a visual marker for clarity; it doesn't actually make a difference in the parser output.

For the Date Finished, it's helpful to put down the date of abandonment:

```
\Title|Date Started|Date Finished|Length
DNF 23% 📕Hamlet|2021/12/30|2022/01/10|400
```

Remember, since `DNF` is just a visual marker, if you don't put down a Date Finished then in the parsed output this item will just be at 23% progress and apparently still in progress (lacking a date finished).

### Head column: series and volume

Previously we saw that the Head column can contain the format, author, and title. But you can put other information in there as well, using the separator ` -- ` (two hyphens surrounded by spaces) after the title.

Series and volume numbers are the most common case:

```
\Title
Night -- The Night Trilogy, #1
Jingo -- in Discworld
```

A series plus volume number must follow the format `<series>, #<n>`, and a series without a volume number must be preceded by `in `.

An item can even be in multiple series. For example, to make that second item more precise:

```
\Title
Jingo -- Discworld, #21 -- City Watch, #4
```

### Head column: extra info

If you want to save any other information, you can do that using the same separator as for series (` -- `):

```
\Title
Cosmos -- 2013 paperback
Utopia -- trans. Robert Adams -- ed. George Logan
Wonder -- in The Wonder Series -- published 2013
```

Extra info is saved separately from series, so `Hamlet` in this example has one string of extra info, plus the series.

Each string of extra info will be saved into a simple `extra_info` array, and it's up to you what to do with those strings. (You may need to further parse those array elements yourself, depending on your needs.)

### Head column: multiple items

Here's a little trick for when you DNF several related items. You can put them all on the same row like this:

```
\Title
DNF 🎤FiveThirtyEight Politics 🎤The NPR Politics Podcast 🎤Pod Save America
```

### Sources column: variants

If you re-read something in a different format or edition, it's nice to keep it in the same row since it's still the same item. The way to do this is with *variants*. These are defined by format emojis in the Sources column:

```
\Title|Sources
Utopia|📕🔊
```

In the next section we'll see how to mark a re-read of a different variant, but for now let's dig deeper into the variants themselves. To add source information to each variant, simply write it out after each format emoji, as you would normally in the Sources column:

```
\Title|Sources
Utopia|📕039393246X 🔊https://librivox.org/utopia-by-thomas-more
Hamlet|📕own 0141396504 📕Lexpub B07C8956BH
```

But variants can specify more than just format and sources. They can specify extra info as well. Earlier we saw these in the Head column, but if they are specific to a variant then they should be in the Sources column instead (but if any extra info should apply to all variants, then keep it in the Head column):

```
\Title|Sources
Utopia|📕039393246X -- trans. Robert Adams -- ed. George Logan 🔊https://librivox.org/utopia-by-thomas-more
Hamlet -- paperback|📕own 0141396504 📕Lexpub B07C8956BH -- No Fear translation
```

An item's length also probably belongs with a specific variant. You can specify the length at the end of the main part of the variant string, just before any extra info:

```
\Title|Sources
Utopia|📕039393246X 336p -- trans. Robert Adams -- ed. George Logan 🔊https://librivox.org/utopia-by-thomas-more 3:59
```

The `p` after the page count is optional, and only for clarity.

### Dates Started column: variants

Now let's actually make use of the variants we saw in the previous section. Suppose you read a book in print, and then again on audio:

```
\Title|Sources|Dates started
Utopia|📕🔊|2021/7/1 v1, 2022/12/1 v2
```

`v1` refers to the first variant, and `v2` to the second, and so on ad infinitum.

`v1` can be omitted, because an *experience* (the technical name for a read/re-read) refers to the first variant by default:

```
\Title|Sources|Dates started
Utopia|📕🔊|2021/7/1, 2022/12/1 v2
```

### Dates Started column: progress

Recall one of our examples from the earlier section on `DNF` ("Did Not Finish"):

```
Title|Dates started|Dates finished|Length
DNF p105 📕Utopia|2021/7/1|2021/8/5|336
```

What if you gave that book another chance as an audiobook? Here's how:

```
Title|Sources|Dates started|Dates finished
Utopia|📕336p 🔊3:59|DNF p105 2021/7/1, 2022/12/1 v2|2021/8/5
```

Then if you DNF again:

```
Title|Sources|Dates started|Dates finished
Utopia|📕336p 🔊3:59|DNF p105 2021/7/1, DNF 0:50 2022/12/1 v2|2021/8/5, 2022/12/24
```

### Dates Started column: group experience

We've been looking at how to shift information into variants, but here's something completely new: a *group experience*. That's when you read/watch/listen as part of a group. You can record that with a special emoji in the Dates Started column, optionally followed by the group name:

```
\Title|Dates started
Hamlet|2022/12/1 🤝🏼Sadvent book club
Cosmos|2021/7/1 🤝🏼
```

If variants are involved, the variant marker comes first before the group:

```
\Title|Dates started
Hamlet|🔊📕|2022/12/1 v2 🤝🏼Sadvent book club
```

### Notes column: special notes

There are two special kinds of notes, each marked by a special emoji: a *blurb* (`💬`) and a *private note* (`🔒`):

```
\Title|Notes
Hamlet|💬A profound meditation on the human experience. -- 🔒Eh, I don't get it.
```

They aren't inherently different from regular notes, but they can come in handy if you're publicly showing your parsed reading log, and you want to specially display a blurb and hide private notes.

### History column

NOTE: Parsing of the History column is TBIS (To Be Implemented Soon). Until that happens, you should fill in Dates Started and Dates Finished in addition to your History column.

#### History: regular item (podcast)

The History column is handy for podcasts. Here's a common scenario: you discover a good podcast, you listen to a bunch of previous episodes until you're caught up, and then you listen to each new episode as they're released.

```
\Rating|Title|Sources|Dates started|Dates finished|Genres|Length|Notes|History
3|🎤Flightless Bird||||podcast|0:50 each||2022/10/06-10/11 x23 -- x1/week
```

- In plain English this means "Each episode is 50 minutes long. From the 6th to the 12th of October, 2022, I listened to 23 episodes of Flightless Bird, and since then I've been listening to an episode each week."
- Notice that the Dates Started and Dates Finished columns are empty. These columns are not parsed if the History column is filled in.
- `x1/week` means once weekly, but you can also use `/day` and `/month`, like this: `x1/day`, `x2/week`, `x10/month`, and so on.

But that's not the only way to listen to a podcast, and so the History column is flexible. For example, what if you stopped listening to that podcast after a while?

```
3|🎤Flightless Bird||||podcast|0:50 each||2022/10/06-10/11 x23 -- -12/14 x1/week -- 2023/3/1- x2/week
```

- This adds, in plain English, "I stopped listening on December 14, and then on March 1 I started listening again, but now I'm listening to two episodes per week."
- If one side of a date range is omitted (here `-12/14` and `2023/3/1-`), that date is inferred from the previous/next date, or if there is no next date then it means "up to the present".
- You can omit the year from dates after the first one, except when the year advances (as in the last entry).

#### History: occasional item (podcast)

What about a podcast that you listen to only occasionally? You may want to keep track of which episodes you've listened to.

```
4|🎤The Bible for Normal People||||podcast|||2022/12/01 0:50 #2 Richard Rohr - A Contemplative Look at The Bible -- 12/9 1:30 #19 Megan DeFranza - The Bible and Intersex Believers -- 12/21 ⭐#160 The Risk of an "Errant" Bible -- 0:50 ⭐#164 Where Did Our Bible Come From? -- 2023/1/1 #5 Mike McHargue - Science and the Bible
```

- Here's the format of each entry: `[date] [h:mm] [star if favorite] #[episode number] [creator or interviewee] [title]`
- But as you can see, not every piece of information is spelled out in every entry. Wherever a length (duration) is omitted, the length from the previous entry is used, or the "each" length in the Length column if there is one (see the next example below). Wherever a date is omitted, the date from the previous entry is used if that was a single date, or (as in the above Flightless Bird example) the date after the previous entry is used if that was a date range.
- The Length column is empty this time because the lengths are different among the episodes.

OK, but what if you want to write down episode titles without having to write down every date? There's a shortcut for that too: you can have entries for the episodes sandwiched between two halves of a date range, like this:

```
4|🎤Escriba Café||||podcast|0:30 each||2021/04/16- Amor -- Diabolus -- Máfia -- Piratas -- 2:00 Trilogia História do Brasil -- Rapa-Nui -- Espíritos -- Inferno -- -4/30 Pompeia
```

- In plain English: "From the 16th to the 30th of April, 2021, I listened to a bunch of episodes, starting with `Amor` and ending with `Pompeia`."
- `0:30 each` in the Length column is the default length, applied to all entries where it's omitted, but the episode `Trilogia História do Brasil` is longer and overrides that default.

#### History: planned and DNF (podcast)

If you've planned out which episodes you want to listen to, you can mark them down as planned simply by a question mark (`?`) in place of the date.

```
|🎤Pray as you go||||religion,podcast|||2022/07/12-17 1:39 Imaginative Contemplation -- 8/29-9/7 1:04 Acts -- ? 2:29 God with Us -- 1:34 God's Grandeur -- DNF 1:17 Way of the Cross
```

- As with a date, the question mark carries over to omitted dates in subsequent entries, so only the first planned item (`God with Us`) needs a question mark.

But then what if you don't like that podcast and you end up DNF'ing parts of it? Here's how to record that:

```
2|DNF 🎤Pray as you go||||podcast|||2022/07/12-17 1:39 Imaginative Contemplation -- 8/29-9/7 1:04 Acts -- DNF 30% -9/17 2:13 God with Us -- DNF @0:15 2:01 God's Grandeur -- DNF 1:17 Way of the Cross
```

- As elsewhere, DNF's may be followed by a percentage or length indicating the stopping point, or the stopping point may be omitted, which means the same as 0%. The only difference is that in the History column, lengths for DNFs need to be preceded by `@` (such as `DNF @0:15` in this example) because otherwise it would be hard to distinguish the DNF length from the length of the episode.
- The `DNF` near the beginning of the row, just before the title, actually has no meaning whenever the History column is filled in; it's just a handy visual marker.

#### History: no names and re-watching (TV show)

Thus far we've been talking about podcasts, but you can use the History column to track any kind of item. Here's a TV show, for example:

```
4|🎞️Eyes on the Prize||||history|1:00 each x14||2021/1/28-2/1 x4 -- -2/3 x5 -- 2/7 -- 2/9 x4 ---- 11/1 -- 11/2
```

- `x14` in the Length column means "There are 14 episodes in total." This gives the item a definite length. It has the same effect as writing `14:00` in the Length column and `1:00 x4` in the first entry, to make all the other entries default to one hour. A third equivalent would be to have just `1:00 each` in the Length column, have `1:00 x4` in the first entry, and then make the last entry of the first watching `2/9 x4 done`, meaning you were done after that one.
- ` ---- ` indicates a re-watching of the show.
- So in plain English: "Each episode is an hour long, and there are 14 episodes. From the 28th of January to the 1st of February, 2021, I watched 4 episodes. From the 2nd to the 3rd of February I watched 5 episodes. On the 7th I watched another episode, and on the 9th I watched four more. In November I started the series over, watching an episode on the 1st and another on the 2nd."

#### History: pages and stopping points (books)

Books work with the History column, too.

```
3|📕Cultish||||religion|319||2022/5/1 @31p -- 5/2 @54p -- 5/6-15 10p -- 5/20 @200p -- 5/21-23 done
```

- `@` means "I stopped at", such as `5/1 @31p` meaning "On 5/1 I stopped at page 31."
- Contrast that with the entry `5/6-15 10p`, without the `@`. Here the page count is an amount read, not a stopping point. This entry means "Between 5/6 and 5/15 I read 10 pages per day."
- The whole example means, in plain English: "The book is 319 pages long. On the 1st of March, 2022, I read up to page 31. On the 2nd I read up to page 54. From the 6th through the 15th I read 10 pages per day. Then on the 20th, I read up to page 200, and from the 21st to the 23rd I finished the book."

And here's an audiobook with a History column similar to the last example:

```
4|🔊Born a Crime||||memoir|8:44||2021/5/1 @0:47 -- 5/2 @1:10 -- 5/6-15 0:30 -- 5/20 @6:50 -- 5/21-23 done
```

A variant can be specified similar to how we've seen in the Dates Started column. For example, if you start re-reading Born a Crime but this time in print:

```
4|Born a Crime|🔊📕|||memoir|8:44||2021/5/1-5/23 done ---- v2 2022/7/1 @p50 -- 7/2 @p90
```

So the history column is not limited to one particular format. I myself find it most useful for podcasts, but the parser is flexible enough that it can apply History entries to any kind of item.

## Next steps

- Start your own reading log by downloading and editing [the reading.csv template](https://github.com/fpsvogel/reading/blob/main/doc/reading.csv).
- See how to use the gem to parse your reading log in [the "Usage" section in the README](https://github.com/fpsvogel/reading/blob/main/README.md#usage).
- To better understand the parsed output from the gem, see [the Parsed Output Guide](https://github.com/fpsvogel/reading/blob/main/doc/parsed-output.md).
