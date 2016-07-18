#
# Обработка offers-файла из 1С Челябинска
#
module VoshodAvtoExchange

  module Parsers

    class ChelOffers < Base

      S_I_ERROR = %Q(Ошибка сохранения товара в базу.
        %{msg}
      ).freeze

      def initialize(
        provider_id:  nil,
        i_attrs:      {},
        doc_info:     {}
      )

        super

        @provider_id = provider_id
        @doc_info    = doc_info
        start_all

      end # new

      def start_element(name, attrs = [])

        super

        case name

          when 'ТипЦены'.freeze then
            start_type_of_price

          when 'Предложение'.freeze then
            start_item

          when 'Цена'.freeze then
            start_item_price

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when 'ТипЦены'.freeze then
            stop_type_of_price

          when 'Предложение'.freeze then
            stop_item
            save_item

          when 'Цена'.freeze then
            stop_item_price

          when 'Ид'.freeze then
            parse_price(:id)
            parse_item(:id)

          when 'Количество'.freeze then
            parse_item(:count)

          when 'Наименование'.freeze then
            parse_price(:name)

          when 'ИдТипаЦены'.freeze then
            parse_item_price(:id)

          when 'ЦенаЗаЕдиницу'.freeze then
            parse_item_price(:value)

        end # case

      end # end_element

      private

      #
      # Обработка цен товаров
      #
      def start_all
        @types_of_prices = {}
      end # start_all

      def start_type_of_price

        @start_type_of_price  = true
        @type_of_price        = {}

      end # start_type_of_price

      def stop_type_of_price

        @start_type_of_price = false

        return if @type_of_price.nil? || @type_of_price.empty?
        @types_of_prices[@type_of_price[:id]] = @type_of_price[:name]

      end # stop_type_of_price

      def price?
        tag == "ТипЦены" && @start_type_of_price
      end # price?

      def parse_price(key)
        @type_of_price[key] = tag_value if price?
      end # parse_price

      #
      # Обработка товаров
      #
      def start_item

        @start_item = true
        @item       = {
          p_id:         @provider_id,
          prices:       {},
          meta_prices:  {}
        }

      end # start_item

      def stop_item
        @start_item = false
      end # stop_item

      def for_item?
        @start_item
      end # item?

      def only_item?
        for_item? && tag == "Предложение".freeze
      end # only_item?

      def parse_item(key, val = nil)
        @item[key] = val || tag_value if only_item?
      end # parse_item

      #
      # Обоаботка цен товара
      #
      def start_item_price

        @start_item_price = true
        @item_price       = {}

      end # start_item_price

      def stop_item_price

        @start_item_price = false

        return if @item_price.nil? || @item_price.empty?

        @item[:prices][@item_price[:id]]      = @item_price[:value].try(:to_f)
        @item[:meta_prices][@item_price[:id]] = @types_of_prices[@item_price[:id]] || 'Неизвестно'


      end # stop_item_price

      def item_price?
        @start_item_price && tag == 'Цена'.freeze
      end # item_price?

      def parse_item_price(key)
        @item_price[key] = tag_value if item_price?
      end # parse_item_price

      def time_stamp

        return @time_stamp unless @time_stamp.nil?
        @time_stamp = @doc_info["ДатаФормирования"].try(:to_time).try(:utc).try(:to_i) || 0

      end # time_stamp

      #
      # Сохранение товара в базе
      #
      def save_item

        return if @item.nil? || @item.empty?

        item = ::Item.find_or_initialize_by(

          p_id:       @item[:p_id],
          p_item_id:  @item[:id]

        )

        item.updated_at   = ::Time.now
        item.prices       = @item[:prices]
        item.meta_prices  = @item[:meta_prices]
        item.count        = @item[:count].try(:to_i) || 0

        begin

          log(S_I_ERROR % {
            msg: item.errors.full_messages
          }) unless item.upsert

        rescue => ex

          log(S_I_ERROR % {
            msg: ex.backtrace.join("\n")
          })

        end

      end # save_item

    end # ChelOffers

  end # Parsers

end # VoshodAvtoExchange
