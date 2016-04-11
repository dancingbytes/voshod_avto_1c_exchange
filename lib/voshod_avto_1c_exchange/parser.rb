require 'voshod_avto_1c_exchange/parsers/base'
require 'voshod_avto_1c_exchange/parsers/user_reg'
require 'voshod_avto_1c_exchange/parsers/user_price'
require 'voshod_avto_1c_exchange/parsers/chel_import'
require 'voshod_avto_1c_exchange/parsers/chel_offers'

#
# Фабрика по выбору парсера обработки данных
#
module VoshodAvtoExchange

  # Класс-шаблон по разбору xml-файлов
  class Parser < ::Nokogiri::XML::SAX::Document

    def self.parse(file, clb = nil, counter = 0)

      parser  = ::Nokogiri::XML::SAX::Parser.new(
        new(clb, counter)
      )
      parser.parse_file(file)

    end # self.parse

    def initialize(clb = nil, counter = 0)

      @parser     = nil
      @doc_info   = {}
      @line       = counter
      @clb        = ->(line, msg) {} unless clb.is_a?(::Proc)

    end # new

    def start_element(name, attrs = [])

      @line += 1
      @clb.call(@line, "Обработка выгрузки...")

      # Если парсер не установлен -- пытаемся его выбрать
      unless @parser

        case name

          when 'КоммерческаяИнформация'.freeze then
            parse_doc_info(::Hash[attrs])

          when 'РегистрацияКлиентов'.freeze then
            @parser = ::VoshodAvtoExchange::Parsers::UserReg.new(doc_info: doc_info)

          when 'Контрагент'.freeze          then
            @parser = ::VoshodAvtoExchange::Parsers::UserPrice.new(doc_info: doc_info)

          # 1c (import)
          when 'Классификатор'.freeze       then init_1c8_import

          # 1c (offers)
          when 'ПакетПредложений'.freeze    then init_1c8_offers(::Hash[attrs])

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

          when 'Ид'.freeze  then
            parser_1c8_import
            parser_1c8_offers

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
      ::VoshodAvtoExchange.log("[XML Errors] #{string}", self.class.name)
    end # error

    def warning(string)
      ::VoshodAvtoExchange.log("[XML Warnings] #{string}", self.class.name)
    end # warning

    private

    def parse_doc_info(attrs)
      @doc_info = attrs
    end # parse_doc_info

    def doc_info
      @doc_info || {}
    end # doc_info

    def init_1c8_import
      @init_1c8_import = true
    end # init_1c8_import

    def init_1c8_offers(attrs)

      @init_1c8_offers  = true
      @attrs_1c8_offers = attrs

    end # init_1c8_offers

    def parser_1c8_import

      return unless @init_1c8_import
      @init_1c8_import = false

      case @str

        # id выгрузки 1С Челябинск
        when "db996b9e-3d2f-11e1-84e7-00237d443107".freeze,
             "db996b9e-3d2f-11e1-84e7-00237d443107#".freeze then

          @parser = ::VoshodAvtoExchange::Parsers::ChelImport.new(
            provider_id:  "db996b9e-3d2f-11e1-84e7-00237d443107",
            doc_info:     doc_info
          )

      end # case

    end # parser_1c8_import

    def parser_1c8_offers

      return unless @init_1c8_offers
      @init_1c8_offers = false

      case @str

        # id выгрузки 1С Челябинск
        when "db996b9e-3d2f-11e1-84e7-00237d443107".freeze,
             "db996b9e-3d2f-11e1-84e7-00237d443107#".freeze then

          @parser = ::VoshodAvtoExchange::Parsers::ChelOffers.new(
            provider_id:  "db996b9e-3d2f-11e1-84e7-00237d443107",
            i_attrs:      @attrs_1c8_offers,
            doc_info:     doc_info
          )

      end # case

      @attrs_1c8_offers = nil

    end # parser_1c8_offers

  end # Parser

end # VoshodAvtoExchange
