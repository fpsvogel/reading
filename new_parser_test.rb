require_relative "lib/reading/util/hash_array_deep_fetch"
require_relative "lib/reading/util/hash_deep_merge"
require_relative "lib/reading/util/string_remove"
require_relative "lib/reading/util/blank"
require_relative "lib/reading/config"
require_relative "lib/reading/parser/row"
require "debug"

str = "3|30% 📕Author Person - Title of Book -- 2017 -- in Book Series -- Other Series, #1 -- ed. me 🔊 Audiobook Title|🔊Hoopla 0862922658 20 -- ed. John -- A Series, #2 🎞️Kanopy 1:03|DNF 20% 2023/3/16 v1 🤝🏼with Jo, 20:03 2023/04/20|2023/03/30,2023/05/07|fiction,history|10:02|Normal note -- 💬a blurb -- 🔒 a private note --"
row = Reading::Parser::Row.new(str, Reading::Config.new.hash)
parsed = row.parse

pp parsed
