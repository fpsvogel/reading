# How to format your CSV file

Welcome! This is a guide to setting up your own CSV reading log to be parsed by the Reading gem. If you want the quickest start possible, download and edit [the reading.csv template](https://github.com/fpsvogel/reading/blob/main/doc/reading.csv), which includes the examples below, and you can refer to the notes below as needed. Then see [the "Usage" section in the README](https://github.com/fpsvogel/reading/blob/main/README.md#usage) for how to parse the CSV file.

## Basics

Here is the beginning of a minimal CSV reading log:

  ```
  \Author - Title|Dates finished
  \------ IN PROGRESS
  Sapiens: A Brief History of Humankind
  Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|2019/06/18, 2020/5/8
  ```

- The first two lines (headers and a section heading) are comments. Any line starting with a backslash (`\`) is a comment and will be ignored by the parser. So you can format these lines however you want.
- Then we have two items, books in this case.
  - Columns are divided by a pipe character (`|`).
  - This means you *must not* use the pipe character anywhere except to divide columns (or in comments).
  - Columns may be omitted from the right, as in the first item.
  - The author is optional. The first item omits it.
  - You're currently re-reading the second item: it has two "Dates finished", making this your third time reading it. Nice!

If this minimal kind of reading log is what you want, be sure to initialize a `Reading::CSV` with unwanted columns disabled:

  ```
  custom_config = {
    csv: {
      columns: {
        # Disables all columns except head and dates_finished.
        rating:         false,
        sources:        false,
        dates_started:  false,
        genres:         false,
        length:         false,
        public_notes:   false,
        blurb:          false,
        private_notes:  false,
        history:        false,
      }
    }
  }
  csv = Reading::CSV.new(path: file_path, config: custom_config)
  ```

You could go even more minimalist and disable the Dates Finished column if you just want to keep a list of titles of books you've read.

But by default, all columns are enabled. Here are those same two items, but now with all columns:

  ```
  \Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates started, Progress|Dates finished|Genres|Length|Public notes|Blurb|Private notes|History
  \------ IN PROGRESS
  |🔊Sapiens: A Brief History of Humankind|Vail Library B00ICN066A|2021/09/20| |history, wisdom|15:17|Ch. 5: "We did not domesticate wheat. It domesticated us." -- End of ch. 8: the ubiquity of patriarchal societies is so far unexplained. It would make more sense for women (being on average more socially adept) to have formed a matriarchal society as among the bonobos. -- Ch. 19: are we happier in modernity? It's doubtful.|History with a sociological bent, with special attention paid to human happiness.
  5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247||||2019/5/1 p31 -- 5/2 p54 -- 5/6-15 10p -- 5/20 p200 -- 5/21 done
  ```

- Wow. That's a lot. But again, you can disable whichever columns you don't want.
- And even when they are all enabled, you don't *have* to fill in every column every time. For example, the first item above omits the contents of the first column, and it omits the last two columns entirely. The second item omits the contents of the last few columns, except for History. See [the History section below](#history) for details on tracking reading history.
- The title is the only piece of information that's required on every line. Everything else is optional.
- Pro tip: entering a row is much less cumbersome if you set up a keyboard shortcut that pastes a row template. I myself use [an AutoHotkey script](https://github.com/fpsvogel/reading/blob/main/doc/autohotkey-reading-csv.rb) for this.

## Advanced

Here are a few more examples. This time, let's list items that you've finished.

  ```
  \Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates started, Progress|Dates finished|Genres|Length|Public notes|Blurb|Private notes|History
  \------ DONE
  4|📕Robert Louis Stevenson - Insula Thesauraria -- in Mount Hope Classics -- trans. Arcadius Avellanus -- unabridged|1533694567|2020/10/20 🤝🏼 weekly Latin reading with Sean and Dennis|2021/08/31|latin, novel|8:18|Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html -- Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d
  2|🔊Total Cat Mojo|gift from neighbor Edith B01NCYY3BV|DNF 50% 2020/03/21, DNF 4:45 2021/08/06|2020/04/01, 2021/08/11|cats|10:13|I would've felt bad if I hadn't tried.
  1|DNF 🎤FiveThirtyEight Politics 🎤The NPR Politics Podcast 🎤Pod Save America| |2021/08/02|2021/08/02|politics, podcast|0:30|Not very deep. Disappointing.
  5|Randall Munroe - What If?: Serious Scientific Answers to Absurd Hypothetical Questions|🔊Lexpub B00LV2F1ZA 6:36 -- unabridged -- published 2016, ⚡Amazon B00IYUYF4A 320 -- published 2014|2021/08/01, 2021/08/16 v2 🤝🏼 with Sam, 2021/09/01|2021/08/15, 2021/08/28, 2021/09/10|science| |Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet.|It's been a long time since I gave highest marks to a "just for fun" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist.
  ```

- **"Robert Louis…":**  The series ("Mount Hope Classics") comes after a special word: "in" (must be lowercase). If the item had a position in the series, you would do this instead: Mount Hope Classics, #5.
  - Extra info can also be indicated after the title: in this example, the translator and the fact that this book is unabridged.
  - If you read/watched something in a group, you can add the group experience emoji (🤝🏼) after a date started, then the group description.
- **"Total Cat Mojo":** DNF means "Did Not Finish". You can specify your stopping point with a percentage, a page count such as "55p", or a time such as "1:03" (hours and minutes). Or you can not specify the stopping point at all, as in the next example. If you attempted the book once or if the stopping point was the same each time you read it, it may be easier just write "DNF" once before the format and title, like this: `2|DNF 50% 🔊Total Cat Mojo|…`
- **"FiveThirtyEight…":** Here we see a multi-item line. This is most useful when you DNF'ed several items and equally disliked them. (But a multi-item line doesn't *have* to be DNF.)
- **"Randall…":** This is an item that you re-read as a different *variant*: in this example, the first variant is an audiobook from Lexpub, and the second variant is an ebook from Amazon.
  - In the Sources column you can describe each variant with these data, in this order: format, source(s), ISBN/ASIN, length, and/or extra info. These are all formatted in the same way as usual.
  - If a variant omits data that can also be in other columns (format, length, extra info), then this data in the variant will be defined by other columns rather than being blank. So if these data are the same across all variants, you can write them down just once in the other columns.
  - The exception is progress (without "DNF") before the title, which only applies to the most recent date. See the second In Progress example earlier: the "50%" before the title describes the current re-reading of the book, not the previous readings.
  - Variants can be separated either by format emojis or (if you omit the emojis) by a double hyphen with a space around it (" -- "). But if you have any extra info in Sources, that divider is already being used there, so in that case you *must* include format emojis even if all the variants have the same format.
  - If you include any format emojis in Sources, then you have to include them for every variant. But the other data can be specified in some variants and not in others.
  - Now let's look at the Date Started column. After each date started you can specify the variant to which it refers with "v" followed by a number, such as "v2" for the second variant, "v3" for the third, and so on.
  - A date started with no variant specified refers to the first variant. In this example, you listened to the audiobook in the first half of August, then you read the ebook in the second half of August, and then in September you listened to the audiobook again.

Whew! That covers all the odd cases that the Reading parser handles, except for the History column, which I've relegated to the Appendix at the bottom since not everyone is so… *careful* as to want to track every page of every day.

I'm open to new ideas, so if you want to add an item in your reading.csv in a different way that the Reading parser *can't* handle currently, then please let me know by adding a feature request at https://github.com/fpsvogel/reading/issues

## Planned items

Next up: planned items, a.k.a. your "to read" list. One way to track this is to have normal items, but without a date started.

  ```
  \------ PLANNED
  |⚡Tom Holt - A Song for Nero|B00GW4U2TM| | |historical fiction|580
  ```

But this method has two disadvantages for listing books that you just *might* read: (a) it takes more time than just jotting down the title, and (b) it takes up a lot of space if you have a long "to read" list.

Here is a quicker and more compact way to jot down planned items:

  ```
  \------ PLANNED
  \HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero, 🔊True Grit @Little Library @Hoopla, 🔊Two Gentlemen of Lebowski @https://www.runleiarun.com/lebowski/
  \SCIENCE: 📕Randall Munroe - How To @Lexpub 🔊Weird Earth @Hoopla @Lexpub
  ```

- For these compact planned items to be parsed, you must:
  - Start the line with a comment character, then a single genre in all caps, then a colon (`:`).
  - Include the format emoji before each item.
- The all-caps genre is changed to lowercase by the parser. So if you have a "science" genre, the items after "SCIENCE" here will be in that same "science" genre.
- At the end of an item you can list sources, each immediately preceded by `@`.
- Commas between items (before format emojis) are optional.

## History

The History column is handy if you want to track your reading/watching/listening in detail. Even if you don't care to track how much you read per day, this column can still be handy for tracking which episodes of a show or podcast you've listened to, without having to clutter up the notes column with that, and without having to manually sum up the total time of the episodes.

NOTE: The Reading gem does not yet parse the History column, but it will in the future.

Here are some examples:

  ```
  \------ DONE
  4|🎞️Eyes on the Prize: America's Civil Rights Movement|https://worldchannel.org/show/eyes-on-the-prize/ https://jeffco.kanopy.com/video/eyes-prize|2021/07/28, 2021/09/01|2021/08/03|history|14:00||||2021/7/28 1:00 -- 7/29 -- 7/30 -- 7/31 x5 -- 8/1 x4 -- 8/2 -- 8/3 ---- 9/1 -- 9/2
  4|🎤Escriba Café|https://www.escribacafe.com/| | |portuguese,history,podcast| | |Most Portuguese podcasts are annoyingly chatty, but this one is the opposite: historical yarns intended to transport you into another time and place.||2021/7/12 0:20 Bella Luna -- 7/13 -- 0:45 -- 7/17 0:30 -- 7/18-21 -- 8/1 As sete Maravilhas
  ```

- **"Eyes on the Prize":** You can use a URL as a source, and you can list multiple sources.
  - This is is also an example of more detailed tracking with the History column, a comma-separated list of dates when you made progress on an item.
  - Only the first date needs to be written out in full.
  - The length of your progress should appear after the date: in this case, one hour on the 28th of July.
  - Length (and date, as we'll see below) can be omitted wherever it is the same as the one last indicated. All of the episodes in this series are one hour long, so in this case the "1:00" after the other dates would be unnecessary, and so it's omitted.
  - "x5" and "x4" mean "five times" and "four times": on the 31st you watched five episodes, and on the 1st you watched four episodes. Then on the 2nd and 3rd you went back to watching just one episode per day as before. (You could also do "7/31 5:00, 8/1 4:00, 8/2 1:00, 8/3" and that means the same thing.)
  - Use " ---- " to start a new perusal (re-watching). (Since you're currently re-watching this, it would make sense to move it up to your "In progress" section of the file, but you don't *have* to.)
  - This example means, in plain English: "On the 28th of July, 2021, I watched for an hour. I did the same on the 29th and 30th. Then over the weekend I went on a bender and watched 5 hours on the 31st and four hours on the 1st of August. I finished up the series by watching an hour on the 2nd and another hour on the 3rd. But I enjoyed the series so much that I started it over in September, watching an hour on the 1st and another hour on the 2nd."
- **"Escriba Café":** Here's a more complex History, where you're listening to a podcast with irregular episode lengths.
  - In this case you left the Dates Started, Dates Finished, and Length columns empty because you think you'll keep listening to a new episode once in a while. Leaving these columns blank means that you don't have to update them every time you watch a new episode; they are automatically inferred based on the dates and lengths in the History column.
  - More specifically, the total length is the sum of the individual lengths in History, the date started is the first date of each re-read in History, and the date finished is the last date of each re-read in History. Technically this means the item is always in a "finished" state, so this approach is best for items that you consume sporadically.
  - You can add extra text after the date, such as (in this example) "Bella Luna" to indicate the title of the first episode. This extra text can appear either before or after the length.
  - This bit may be confusing: " -- 7/13 -- 0:45 ". In the first entry, the length is omitted, which means the length is the same as the previous entry. In the second entry, the date is omitted, which means the date is the same as the previous entry. So, on the 13th of July I listened to an episode of the same length as last time, and on that same day I also listened to another episode that was 45 minutes long.
  - This example means, in plain English: "On the 12th of July, 2021, I listened to the episode Bella Luna, which was twenty minutes long. Then on the 13th I listened to another episode of the same length. Then on the same day I listened to a 45-minute episode. On the 17th I listened to a half-hour episode, then from the 18th through the 21st I listened to one episode per day, each of them half an hour long. On the 1st of August, I listened to another half-hour episode called As sete Maravilhas."
  - If you wanted to track this History more simply, you could just write an average episode length after the first date, so this example would look like this: "2021/07/12 0:30, 7/13 x2, 7/17, 7/18-21, 8/1". You could even omit the months wherever unnecessary: "2021/07/12 0:30, 13 x2, 17, 18-21, 8/1".

Now let's go back to our novel Goatsong, way above in the "In progress" examples, to take another look at its History column:

  ```
  5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247||||2019/5/1 p31 -- 5/2 p54 -- 5/6-15 10p -- 5/20 p200 -- 5/21 done
  ```

- Here's what we can learn from this example:
  - Length can be in pages, such as "5/1 p31" meaning "on 5/1 I read 31 pages".
  - But in this example we see "5/1 p31", with the "p" before the number. This means "on 5/1 I read up until page 31". This is useful for longer items like books and audiobooks, where it's easier to see your stopping point than to calculate how much you read or listened to in a day.
  - To do the same with times, use a leading hyphen: "5/1 -4:00" means "On the 1st of May I listened/watched up to the 4-hour mark."
  - "5/23 done" is shorthand for the last page, "5/23 p247".
  - This example means, in plain English: "On the 1st of March, 2019, I read up to page 31. On the 2nd I read up to page 54. From the 6th through the 15th I read 10 pages per day. Then on the 20th, I read up to page 200, and on the 21st I finished the book."
