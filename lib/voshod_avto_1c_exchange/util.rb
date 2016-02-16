module VoshodAvtoExchange

  module Util

    extend self

    def to_1c_id(str)

      uid = str.to_s.ljust(32, '0')
      "#{uid[0,8]}-#{uid[8,4]}-#{uid[12,4]}-#{uid[16,4]}-#{uid[20,12]}"

    end # to_1c_id

    def to_bson_id(str)
      str.gsub(/-/, '')[0, 24]
    end # to_bson_id

    def humanize_time(secs)

      [
        [60,    :сек],
        [60,    :мин],
        [24,    :ч],
        [1000,  :д]
      ].freeze.map { |count, name|

        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i} #{name}"
        end

      }.compact.reverse.join(' ')

    end # humanize_time

    def clean_whitespaces(str)
      clean_whitespaces!(str.clone)
    end # clean_whitespaces

    def clean_whitespaces!(str)

      str.sub!(/\A\s+/, "")
      str.sub!(/\s+\z/, "")
      str.gsub!(/(\s){2,}/, '\\1')
      str

    end # clean_whitespaces

  end # Util

end # VoshodAvtoExchange
