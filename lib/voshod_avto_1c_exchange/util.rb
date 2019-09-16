# encoding: utf-8
module VoshodAvtoExchange

  module Util

    extend self

    CROSS_RE = /[\-\.\s]/.freeze

    def to_1c_id(str)

      uid = str.to_s.ljust(32, '0')
      "#{uid[0,8]}-#{uid[8,4]}-#{uid[12,4]}-#{uid[16,4]}-#{uid[20,12]}"

    end

    def humanize_time(secs)

      res = [
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

      res.blank? ? '0 сек' : res

    end # humanize_time

    def xml_escape(str)

      str = str.to_s.dup
      str.gsub!(/&/, "&amp;")
      str.gsub!(/'/, "&apos;")
      str.gsub!(/"/, "&quot;")
      str.gsub!(/>/, "&gt;")
      str.gsub!(/</, "&lt;")
      str

    end # xml_escape

    def xml_unescape(str)

      str = str.to_s.dup
      str.gsub!("&amp;", '&')
      str.gsub!("&apos;", "'")
      str.gsub!("&quot;", '"')
      str.gsub!("&gt;", '>')
      str.gsub!("&lt;", '<')
      str

    end # xml_escape

  end # Util

end # VoshodAvtoExchange
