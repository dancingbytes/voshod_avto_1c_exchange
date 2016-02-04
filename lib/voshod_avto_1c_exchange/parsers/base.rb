#
# Класс с базовым функционалом по рабору xml-файлов.
#
module VoshodAvtoExchange

  module Parsers

    class Base

      def initialize

        @str    = ""
        @level  = 0
        @tags   = {}
        @attrs  = {}

      end # initialize

      def start_element(name, attrs = [])

        @str          = ""
        @level        += 1
        @tags[@level] = name
        @attrs        = ::Hash[attrs]

      end # start_element

      def end_element(name)
        @level -= 1
      end # end_element

      def characters(str)
        @str << squish_str(str) unless str.blank?
      end # characters

      private

      def start_parse_params

        @start_parse_params = true
        @parse_params       = {}

      end # start_parse_params

      def stop_parse_params
        @start_parse_params = false
      end # stop_parse_params

      def parse_params(name)
        @parse_params[name] = @str if @start_parse_params
      end # parse_params

      # Параметры парсинга
      def params
        @parse_params || {}
      end # params

      # Тег
      def tag
        @tags[@level]
      end # tag

      # Параметры тега
      def attrs
        @attrs || {}
      end # attrs

      # Уровень вложенности
      def level
        @level || 0
      end # level

      # Содержимое тега
      def tag_value
        @str
      end # tag_value

      def tag_debug
        "<#{tag} #{attrs.inpect}>#{tag_value}</#{tag}>"
      end # tag_debug

      def log(msg)
        ::VoshodAvtoExchange.log("#{self.name} -> #{msg}")
      end # log

      def squish_str(str)
        str.split.join(' ')
      end # squish_str

    end # Base

  end # Parsers

end # VoshodAvtoExchange
