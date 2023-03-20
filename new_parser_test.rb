# require_relative "lib/reading/util/hash_array_deep_fetch"
# require_relative "lib/reading/util/hash_deep_merge"
# require_relative "lib/reading/util/hash_compact_by_template"
# require_relative "lib/reading/util/string_remove"
# require_relative "lib/reading/util/string_truncate"
# require_relative "lib/reading/util/blank"
# require_relative "lib/reading/errors"
# require_relative "lib/reading/config"
# require_relative "lib/reading/parser/parse"
# require_relative "lib/reading/parser/transform"
require_relative "lib/reading"

require "debug"

str = "|Sapiens||||||||something"

config = Reading::Config.new.hash
# parsed = Reading::Parser::Parse.new(config).parse_row_to_intermediate_hash(str)
# items = parsed
# items = Reading::Parser::Transform.new(config).transform_intermediate_hash_to_item_hashes(parsed)

items = Reading.parse(str, config:)

pp items
