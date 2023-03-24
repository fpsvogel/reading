#!/home/felipe/.rbenv/shims/ruby

# This script tranforms the line at the cursor into a reading.csv row.
# By mapping this script to a keyboard shortcut, entering a new row
# becomes just a matter of filling in a few blank columns.

# Sleep a bit because the keyboard shortcut needs to have been released first.
sleep 0.2

# Cut the line/selection, then grab it from the clipboard. Typically this is the
# head (format, author, title) optionally followed by the Source column.
`xdotool key "ctrl+x"`
cut = `xclip -o -selection clipboard`

comment_char = "\\"
cut = cut.delete_prefix(comment_char).chomp

# If the Source column is already present, do not add a column separator for it.
if cut.include? "|"
  source_sep = ""
else
  source_sep = "|"
end

start_date = `date +'%Y/%m/%d'`.chomp

row = "|#{cut}#{source_sep}|#{start_date}|||"

# Output the row to the clipboard, then paste it.
`echo "#{row}" | xclip -f -selection clipboard`
sleep 0.05
`xdotool key "ctrl+v"`
sleep 0.05

# Move the cursor to the Genres column.
`xdotool key Left`
`xdotool key Left`
