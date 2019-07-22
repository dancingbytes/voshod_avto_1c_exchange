#
# Класс с базовым функционалом по разбору xml-файлов.
#
module VoshodAvtoExchange

  module Parsers

    class Base

      def initialize(*args)

        @str    = ""
        @level  = 0
        @tags   = {}
        @attrs  = {}

      end

      def start_element(name, attrs = [])

        @str          = ""
        @level        += 1
        @tags[@level] = name
        @attrs        = ::Hash[attrs]

      end

      def end_element(name)
        @level -= 1
      end

      def characters(str)
        @str << str unless str.blank?
      end

      def end_document
      end

      private

      # Тег
      def tag(diff = 0)
        @tags[level + diff]
      end

      # Параметры тега
      def attrs
        @attrs || {}
      end

      # Уровень вложенности
      def level
        @level || 0
      end

      # Содержимое тега
      def tag_value
        ::VoshodAvtoExchange::Util.xml_unescape(@str)
      end

      alias :value :tag_value

      def tag_debug
        "<#{tag} #{attrs.inspect}>#{tag_value}</#{tag}>"
      end

      def log(msg)
        ::VoshodAvtoExchange.log(msg, self.class.name)
      end

    end # Base

  end # Parsers

end # VoshodAvtoExchange
