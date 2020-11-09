# encoding: utf-8
require 'voshod_avto_1c_exchange/parsers/base'

require 'voshod_avto_1c_exchange/parsers/user_reg'
require 'voshod_avto_1c_exchange/parsers/user_price'
require 'voshod_avto_1c_exchange/parsers/order'
require 'voshod_avto_1c_exchange/parsers/chel_import'
require 'voshod_avto_1c_exchange/parsers/chel_offers'
require 'voshod_avto_1c_exchange/parsers/chel_cross'
require 'voshod_avto_1c_exchange/parsers/outlet'
require 'voshod_avto_1c_exchange/parsers/delivery_area'

#
# Фабрика по выбору парсера обработки данных
#
module VoshodAvtoExchange

  # Класс-шаблон по разбору xml-файлов
  class Parser < ::Nokogiri::XML::SAX::Document

    STAT_INFO_S = %Q(Обработка файла: %{s} из %{e}).freeze

    def self.parse(
      # Файл обработки
      file,
      # Колбек вызова счетчика
      clb: nil,

      # Начало отсчета счетчика
      cstart: 0,

      # Всего строк для обработки
      tlines: 0
    )

      total   = 0
      parser  = ::Nokogiri::XML::SAX::Parser.new(
        new(
          file_name:  ::File.basename(file),
          clb:        clb,
          cstart:     cstart,
          tlines:     tlines,
          final_clb:  ->(lines) { total = lines }
        )
      )
      parser.parse_file(file)
      total

    end # self.parse

    def initialize(file_name: nil, clb: nil, cstart: 0, tlines: 0, final_clb: nil)

      @parser       = nil
      @doc_info     = {}

      @file_name    = file_name
      @line         = 0
      @cstart       = cstart

      clb           = ->(line, msg) {} unless clb.is_a?(::Proc)
      final_clb     = ->(line) {}      unless final_clb.is_a?(::Proc)

      @clb          = clb
      @final_clb    = final_clb

      # Через какой промеужток идет обнволение счетчика
      # Если обновлять счетчик на каждом теге -- замедляет работу
      @counter_step = (tlines / 100)
      @counter_step = 100 if @counter_step < 100

      # Всего строк для обработки
      @total_lines  = tlines

      info_progress

    end # new

    def start_element(name, attrs = [])

      # Если парсер не установлен -- пытаемся его выбрать
      unless @parser

        case name

        when 'КоммерческаяИнформация'.freeze then
          parse_doc_info(::Hash[attrs])

        # Регистрация клиента
        when 'РегистрацияКлиентов'.freeze then
          @parser = ::VoshodAvtoExchange::Parsers::UserReg.new(doc_info: doc_info)

        # Цены клиентов
        when 'Контрагент'.freeze          then
          @parser = ::VoshodAvtoExchange::Parsers::UserPrice.new(doc_info: doc_info)

          # Обработка заказов
        when 'Документ'.freeze            then
            @parser = ::VoshodAvtoExchange::Parsers::Order.new(doc_info: doc_info)

        # 1c (import)
        when 'Классификатор'.freeze       then init_1c8_import

        # 1c (offers)
        when 'ПакетПредложений'.freeze    then init_1c8_offers(::Hash[attrs])

        # Кроссы из 1С Восход-авто
        when 'Кросы'.freeze then
          @parser = ::VoshodAvtoExchange::Parsers::ChelCross.new

          # Торговые точки
          when 'ТорговаяТочка'.freeze then
            @parser = ::VoshodAvtoExchange::Parsers::Outlet.new(doc_info: doc_info)
          
          # Районы доставки
          when 'РайонДоставки'.freeze then
          @parser = ::VoshodAvtoExchange::Parsers::DeliveryArea.new(doc_info: doc_info)
          
        end # case

      end # unless

      # Если парсер выбран -- работаем.
      @parser.start_element(name, attrs) if @parser

    end # start_element

    def end_element(name)

      if @parser
        @parser.end_element(name)
        
        # TODO 
        # сбрасываем парсер для выбора другого
        @parser = nil if name == "РайоныДоставки".freeze

      else

        case name

          when 'Ид'.freeze  then
            parser_1c8_import
            parser_1c8_offers         

        end

      end # if

      @line += 1

      info_progress if @line % @counter_step == 0

    end # end_element

    def characters(str)

      @str = str
      @parser.try(:characters, str)

    end # characters

    def end_document

      @parser.try(:end_document)
      @parser = nil

      @line += 1

      @clb.call(@cstart + @line, "Документ обработан.")
      @final_clb.call(@cstart + @line)

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
            p_code:   ::VoshodAvtoExchange::P_CODE,
            doc_info: doc_info
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
            p_code:     ::VoshodAvtoExchange::P_CODE,
            i_attrs:    @attrs_1c8_offers,
            doc_info:   doc_info
          )

      end # case

      @attrs_1c8_offers = nil

    end # parser_1c8_offers

    def info_progress

      @clb.call(@cstart + @line, STAT_INFO_S % {
        s:  @line,
        e:  @total_lines
      })
      self

    end # info_progress

  end # Parser

end # VoshodAvtoExchange
