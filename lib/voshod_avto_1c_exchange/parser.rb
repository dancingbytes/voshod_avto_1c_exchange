require 'voshod_avto_1c_exchange/parsers/base'
require 'voshod_avto_1c_exchange/parsers/user_reg'
require 'voshod_avto_1c_exchange/parsers/user_price'

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

          when 'РегистрацияКлиентов' then
            @parser = ::VoshodAvtoExchange::Parsers::UserReg.new

          when 'Контрагент' then
            @parser = ::VoshodAvtoExchange::Parsers::UserPrice.new

        end # case

      end # unless

      # Если парсер выбран -- работаем.
      @parser.start_element(name, attrs) if @parser

    end # start_element

    def end_element(name)
      @parser.try(:end_element, name)
    end # end_element

    def characters(str)
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

  end # Parser

end # VoshodAvtoExchange
