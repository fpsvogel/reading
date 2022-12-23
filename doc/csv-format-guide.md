<!-- omit in toc -->
# How to format your CSV file

Welcome! This is a guide to setting up your own CSV reading log to be parsed by the Reading gem. If you want the quickest start possible, download and edit [the reading.csv template](https://github.com/fpsvogel/reading/blob/main/doc/reading.csv), which includes the examples below, and you can refer to the notes below as needed. Then see [the "Usage" section in the README](https://github.com/fpsvogel/reading/blob/main/README.md#usage) for how to use the gem to parse the CSV file.

### Table of contents
- [Preliminaries: how to edit a CSV file pleasantly](#preliminaries-how-to-edit-a-csv-file-pleasantly)
- [A minimal reading log](#a-minimal-reading-log)
- [Basics](#basics)
  - [Rating column](#rating-column)
  - [Head column (format, author, title)](#head-column-format-author-title)
  - [Sources column](#sources-column)
  - [Dates Started and Dates Finished columns](#dates-started-and-dates-finished-columns)
  - [Genres column](#genres-column)
  - [Length column](#length-column)
  - [Notes column](#notes-column)
- [Advanced](#advanced)
  - [History column](#history-column)
  - [Misc. advanced](#misc-advanced)

## Preliminaries: how to edit a CSV file pleasantly

- I highly recommend the [Rainbow CSV](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv) for VS Code. It's perfect for editing CSV files with lots of columns and potentially long columns, as your reading log is likely to have.
- Entering a row is much less cumbersome if you set up a keyboard shortcut that pastes a row template. I myself use [an AutoHotkey script](https://github.com/fpsvogel/reading/blob/main/doc/autohotkey-reading-csv.rb) for this.

## A minimal reading log

Here is the beginning of a minimal CSV reading log:

```
\Author, Title|Dates finished
Sapiens: A Brief History of Humankind
Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|2019/06/18, 2020/5/8
```

- The first line (containing headers) is a comment because it starts with a backslash (`\`). Comments are ignored by the parser. The header comment is not special; you can put whatever you want in it, or you can omit it altogether.
- Then we have two items, books in this case.
- Columns are divided by a pipe character (`|`).
- This means you *must not* use the pipe character anywhere except to divide columns (or in comments).
- Empty columns on the right side may be omitted, as in the first item.
- The author is optional. The first item omits it.
- To sum up these two rows: you haven't read *Sapiens* yet, and you've read *Goatsong* twice. Nice!

If this minimal kind of reading log is what you want, see example in the ["Custom config"](https://github.com/fpsvogel/reading/blob/main/README.md#custom-config) section of the README.

You could go even more minimalist and disable the Dates Finished column if you just want to keep a list of books you've read.

By default, all columns are enabled. We'll learn about each column in turn, but first here are those same two items but now with all columns:

```
\Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates started|Dates finished|Genres|Length|Notes|History
|🔊Sapiens: A Brief History of Humankind|Vail Library B00ICN066A|2021/09/20||history, wisdom|15:17|💬History with a sociological bent, with special attention paid to human happiness. -- Ch. 5: "We did not domesticate wheat. It domesticated us." -- Discussion of that point: https://www.reddit.com/r/AskHistorians/comments/2ttpn2
5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247
```

Before we dive into each column, here are some general observations:

- As we saw in our minimal example, you don't *have* to fill in every column every time. For example, the first item above omits the contents of the Rating and Dates Finished columns. Both items omit the History (rightmost) column entirely, and the second item omits the column before that as well.
- The title is the only piece of information that's required on every line. Everything else is optional.

## Basics

### Rating column

### Head column (format, author, title)

### Sources column

### Dates Started and Dates Finished columns

### Genres column

### Length column

### Notes column

## Advanced

### History column

NOTE: Parsing of the History column is TBIS (To Be Implemented Soon).

The History column is handy for podcasts. Here's a common scenario: you discover a good podcast, you listen to a bunch of previous episodes until you're caught up, and then you listen to each new episode as they're released.

```
\Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates started|Dates finished|Genres|Length|Notes|History
3|🎤Flightless Bird -- with David Farrier|Spotify https://armchairexpertpod.com/flightless-bird|||podcast|0:50 each||2022/10/06-10/11 x23 -- x1/week
```

- In plain English this means "Each episode is 50 minutes long. From the 6th to the 12th of October, 2022, I listened to 23 episodes of Flightless Bird, and since then I've been listening to an episode each week."
- Notice that the Dates Started and Dates Finished columns are empty. These columns are not parsed if the History column is filled in.
- `x1/week` means once weekly, but you can also use `/day` and `/month`, like this: `x1/day`, `x2/week`, `x10/month`, and so on.

But that's not the only way to listen to a podcast, and so the History column is flexible. For example, what if you stopped listening to that podcast after a while?

```
3|🎤Flightless Bird -- with David Farrier|Spotify https://armchairexpertpod.com/flightless-bird|||podcast|0:50 each||2022/10/06-10/11 x23 -- -12/14 x1/week -- 2023/3/1- x2/week
```

- This adds, in plain English, "I stopped listening on December 14, and then on March 1 I started listening again, but now I'm listening to two episodes per week."
- If one side of a date range is omitted (here `-12/14` and `2023/3/1-`), that date is inferred from the previous/next date, or if there is no next date then it means "up to the present".
- You can omit the year from dates after the first one, except when the year advances (as in the last entry).

What about a podcast that you listen to only occasionally? You may want to keep track of which episodes you've listened to.

```
4|🎤Pete Enns & Jared Byas - The Bible for Normal People|https://peteenns.com/podcast|||religion,podcast|||2022/12/01 0:50 #2 Richard Rohr - A Contemplative Look at The Bible -- 12/9 1:30 #19 Megan DeFranza - The Bible and Intersex Believers -- 12/21 ⭐#160 The Risk of an "Errant" Bible -- 0:50 ⭐#164 Where Did Our Bible Come From? -- 2023/1/1 #5 Mike McHargue - Science and the Bible
```

- Here's the format of each entry: `[date] [h:mm] [star if favorite] #[episode number] [creator or interviewee] [title]`
- But as you can see, not every piece of information is spelled out in every entry. Wherever a length (duration) is omitted, the length from the previous entry is used, or the "each" length in the Length column if there is one (see the next example below). Wherever a date is omitted, the date from the previous entry is used if that was a single date, or (as in the above Flightless Bird example) the date after the previous entry is used if that was a date range.
- The Length column is empty this time because the lengths are different among the episodes.

OK, but what if you want to write down episode titles without having to write down every date? There's a shortcut for that too: you can have entries for the episodes sandwiched between two halves of a date range, like this:

```
4|🎤Escriba Café|https://www.escribacafe.com|||portuguese,history,podcast|0:30 each|💬Most Portuguese podcasts are annoyingly chatty, but this one is the opposite: stories from history with high production value. Love it.|2021/04/16- Até que a morte nos separe -- Bella Luna -- Experiências -- Teorias das Conspiração -- Os tempos estão mudando -- Os Pobres Cavaleiros -- A Colônia de Roanoke -- O Legado Grego -- 2:00 Trilogia História do Brasil -- A Franco-Maçonaria -- Diabolus -- Máfia -- -4/30 William Shakespeare
```

- In plain English: "From the 16th to the 30th of April, 2021, I listened to a bunch of episodes, starting with `Até que a morte nos separe` and ending with `William Shakespeare`."
- `0:30 each` in the Length column is the default length, applied to all entries where it's omitted, but the episode `Trilogia História do Brasil` is longer and overrides that default.

If you've planned out which episodes you want to listen to, you can mark them down as planned simply by a question mark (`?`) in place of the date.

```
|🎤Pray as you go|https://soundcloud.com/pray-as-you-go/sets|||religion,podcast|||2022/07/12-17 1:39 Imaginative Contemplation -- 8/29-9/7 1:04 Acts of the Apostles -- ? 2:13 All the Generations -- 2:01 Dwelling with God -- 2:29 God with Us -- 1:34 God's Grandeur
```

- As with a date, the question mark carries over to omitted dates in subsequent entries, so only the first planned item (`All the Generations`) needs a question mark.

But then what if you don't like that podcast and you end up DNF'ing parts of it? Here's how to record that:

```
2|DNF 🎤Pray as you go|https://soundcloud.com/pray-as-you-go/sets|||religion,podcast|||2022/07/12-17 1:39 Imaginative Contemplation -- 8/29-9/7 1:04 Acts of the Apostles -- DNF 30% -9/17 2:13 All the Generations -- DNF (0:15) 2:01 Dwelling with God -- DNF 2:29 God with Us -- DNF 1:34 God's Grandeur
```

- As elsewhere, DNF's may be followed by a percentage or length indicating the stopping point, or the stopping point may be omitted, which means the same as 0%. The only difference is that in the History column, lengths for DNFs need to be in parentheses (such as `DNF (0:15)` in this example) because otherwise it would be hard to distinguish the DNF length from the length of the episode.
- The `DNF` near the beginning of the row, just before the title, actually has no meaning whenever the History column is filled in; it's just a handy visual marker.

Thus far we've been talking about podcasts, but you can use the History column to track any kind of item. Here's a TV show, for example:

```
\------ DONE
4|🎞️Eyes on the Prize: America's Civil Rights Movement|https://worldchannel.org/show/eyes-on-the-prize|||history|1:00 each x14||2021/1/28-2/1 x4 -- -2/3 x5 -- 2/7 -- 2/9 x4 ---- 11/1 -- 11/2
```

- `x14` in the Length column means "There are 14 episodes in total." This gives the item a definite length. It has the same effect as writing `14:00` in the Length column and `1:00 x4` in the first entry, to make all the other entries default to one hour. A third equivalent would be to have just `1:00 each` in the Length column, have `1:00 x4` in the first entry, and then make the last entry of the first watching `2/9 x4 done`, meaning you were done after that one.
- ` ---- ` indicates a re-watching of the show.
- So in plain English: "Each episode is an hour long, and there are 14 episodes. From the 28th of January to the 1st of February, 2021, I watched 4 episodes. From the 2nd to the 3rd of February I watched 5 episodes. On the 7th I watched another episode, and on the 9th I watched four more. In November I started the series over, watching an episode on the 1st and another on the 2nd."

Using the History column you can even track your progress in a book.

```
5|📕John Green - The Anthropocene Reviewed|Lexpub B08GJVLGGX|||essays|293||2022/5/1 p31 -- 5/2 p54 -- 5/6-15 10p -- 5/20 p200 -- 5/21-23 done
```

- Length can be in pages, such as `5/1 p31` meaning "On 5/1 I read through page 31."
- To do the same with times (e.g. for an audiobook), use a leading hyphen: `5/1 -1:00` means "On the 1st of May I listened/watched up to the one-hour mark."
- But in another entry, `5/6-15 10p`, the "p" comes after the number. This means "Between 5/6 and 5/15 I read 10 pages per day."
- This example means, in plain English: "The book is 293 pages long. On the 1st of March, 2022, I read up to page 31. On the 2nd I read up to page 54. From the 6th through the 15th I read 10 pages per day. Then on the 20th, I read up to page 200, and from the 21st to the 23rd I finished the book."

### Misc. advanced

Here are a few more examples. This time, let's list items that you've finished.

```
\Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates started|Dates finished|Genres|Length|Notes|History
\------ DONE
4|📕Robert Louis Stevenson - Insula Thesauraria -- in Mount Hope Classics -- trans. Arcadius Avellanus -- unabridged|1533694567|2020/10/20 🤝🏼 weekly Latin reading with Sean and Dennis|2021/08/31|latin, novel|8:18|Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html -- Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d
2|🔊Total Cat Mojo|gift from neighbor Edith B01NCYY3BV|DNF 50% 2020/03/21, DNF 4:45 2021/08/06|2020/04/01, 2021/08/11|cats|10:13|🔒I would've felt bad if I hadn't tried.
1|DNF 🎤FiveThirtyEight Politics 🎤The NPR Politics Podcast 🎤Pod Save America||2021/08/02|2021/08/02|politics, podcast|0:30|Not very deep. Disappointing.
5|Randall Munroe - What If?: Serious Scientific Answers to Absurd Hypothetical Questions|🔊Lexpub B00LV2F1ZA 6:36 -- unabridged -- published 2016 ⚡Amazon B00IYUYF4A 320 -- published 2014|2021/08/01, 2021/08/16 v2 🤝🏼 with Sam, 2021/09/01|2021/08/15, 2021/08/28, 2021/09/10|science||Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet. -- 💬It's been a long time since I gave highest marks to a "just for fun" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist.
```

- **"Robert Louis…":**  The series ("Mount Hope Classics") comes after a special word: `in` (must be in lowercase). If the item had a position in the series, you would do this instead: `Mount Hope Classics, #5`.
  - Extra info can also be indicated after the title: in this example, the translator and the fact that this book is unabridged.
  - If you read/watched something in a group, you can add the group experience emoji (🤝🏼) after a date started, then the group description.
- **"Total Cat Mojo":** `DNF` means "Did Not Finish". You can specify your stopping point with a percentage, a page count such as `55p`, or a time such as `1:03` (hours and minutes). Or you can not specify the stopping point at all, as in the next example. If you attempted the book once or if the stopping point was the same each time you read it, it may be easier just write `DNF` once before the format and title, like this: `2|DNF 50% 🔊Total Cat Mojo|…`
  - `🔒` is the "private" symbol. A note that contains that emoji should not be shown publicly.
- **"FiveThirtyEight…":** Here we see a multi-item line. This is most useful when you DNF'ed several items and equally disliked them. (But a multi-item line doesn't *have* to be DNF.)
- **"Randall…":** This is an item that you re-read as a different *variant*: in this example, the first variant is an audiobook from Lexpub, and the second variant is an ebook from Amazon.
  - In the Sources column you can describe each variant with these data, in this order: format, source(s), ISBN/ASIN, length, and/or extra info. These are all formatted in the same way as usual.
  - If a variant omits data that can also be in other columns (format, length, extra info), then this data in the variant will be defined by other columns rather than being blank. So if these data are the same across all variants, you can write them down just once in the other columns.
  - The exception is progress (without `DNF`) before the title, which only applies to the most recent date. See the second In Progress example earlier: the `50%` before the title describes the current re-reading of the book, not the previous readings.
  - Variants can be separated either by format emojis or (if you omit the emojis) by a double hyphen with a space around it (` -- `). But if you have any extra info (series, etc.) in Sources, that divider is already being used there, so in that case you *must* include format emojis even if all the variants have the same format.
  - If you include any format emojis in Sources, then you have to include them for every variant. But the other data can be specified in some variants and not in others.
  - Now let's look at the Date Started column. After each date started you can specify the variant to which it refers with `v` followed by a number, such as `v2` for the second variant, `v3` for the third, and so on.
  - A date started with no variant specified refers to the first variant. In this example, you listened to the audiobook in the first half of August, then you read the ebook in the second half of August, and then in September you listened to the audiobook again.
  - `💬` in a note means that note is a blurb, suitable for special display (if e.g. your favorite books are shown on your website).

Whew! That covers all the odd cases that the Reading parser handles, except for the History column, which is covered in a separate section below.

I'm open to new ideas, so if you want to add an item in your reading.csv in a different way that the Reading parser *can't* handle currently, then please let me know by adding a feature request at https://github.com/fpsvogel/reading/issues
