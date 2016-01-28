require 'voshod_avto_1c_exchange/parsers/user_reg'

module VoshodAvtoExchange

  # Класс-шаблон по разбору товарных xml-файлов
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

        end # case

      end # unless

      # Если парсер выбран -- работаем.
      @parser.start_element(name, attrs) if @parser

    end # start_element

    def end_element(name)
      @parser.end_element(name) if @parser
    end # end_element

    def characters(str)
      @parser.characters(str)   if @parser
    end # characters

    def error(str)
      @parser.error(str)   if @parser
    end # error

    def warning(str)
      @parser.warning(str) if @parser
    end # warning

    def end_document

      @parser.end_document if @parser
      @parser = nil

    end # end_document

  end # Parser

end # VoshodAvtoExchange
