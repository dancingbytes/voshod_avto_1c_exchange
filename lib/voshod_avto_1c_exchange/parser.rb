require 'voshod_avto_1c_exchange/parsers/base'
require 'voshod_avto_1c_exchange/parsers/user_reg'
require 'voshod_avto_1c_exchange/parsers/user_price'
require 'voshod_avto_1c_exchange/parsers/chel_import'

#
# Фабрика по выбору парсера обработки данных
#
module VoshodAvtoExchange

  # Класс-шаблон по разбору xml-файлов
  class Parser < ::Nokogiri::XML::SAX::Document

    def self.parse(file)

      parser  = ::Nokogiri::XML::SAX::Parser.new(new)
      parser.parse_file(file)

    end # self.parse

    def initialize
      @parser = nil
    end # new

    def start_element(name, attrs = [])

      # Если парсер не установлен -- пытаемся его выбрать
      unless @parser

        case name

          when 'РегистрацияКлиентов'.freeze then
            @parser = ::VoshodAvtoExchange::Parsers::UserReg.new

          when 'Контрагент'.freeze          then
            @parser = ::VoshodAvtoExchange::Parsers::UserPrice.new

          # 1c (import)
          when 'Классификатор'.freeze       then init_1c8_import

        end # case

      end # unless

      # Если парсер выбран -- работаем.
      @parser.start_element(name, attrs) if @parser

    end # start_element

    def end_element(name)

      if @parser
        @parser.end_element(name)
      else

        case name

          # 1c8 (import)
          when 'Ид'.freeze  then parser_1c8_import

        end

      end # if

    end # end_element

    def characters(str)

      @str = str
      @parser.try(:characters, str)

    end # characters

    def end_document

      @parser.try(:end_document)
      @parser = nil

    end # end_document

    def error(string)
      ::VoshodAvtoExchange.log "[XML Errors] #{string}"
    end # error

    def warning(string)
      ::VoshodAvtoExchange.log "[XML Warnings] #{string}"
    end # warning

    private

    def init_1c8_import
      @init_1c8_import = true
    end # init_1c8_import

    def parser_1c8_import

      return unless @init_1c8_import
      @init_1c8_import = false

      case @str

        # id выгрузки 1С Челябинск
        when "db996b9e-3d2f-11e1-84e7-00237d443107".freeze then
          @parser = ::VoshodAvtoExchange::Parsers::ChelImport.new(@str)

      end # case

    end # parser_1c8_import

  end # Parser

end # VoshodAvtoExchange
