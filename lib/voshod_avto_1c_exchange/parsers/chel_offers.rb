#
# Обработка offers-файла из 1С Челябинска
#
module VoshodAvtoExchange

  module Parsers

    class ChelOffers < Base

      ITEM_INSERT_OR_UPDATE = %{
        INSERT INTO items (
          p_code,
          mog,
          oem_num,
          oem_brand,
          shipment,
          updated_at,
          va_item_id,
          prices,
          meta_prices,
          count,
          storehouses
        ) VALUES (
          %{p_code},
          %{mog},
          %{oem_num},
          %{oem_brand},
          %{shipment},
          %{updated_at},
          %{va_item_id},
          %{prices},
          %{meta_prices},
          %{count},
          %{storehouses}
        ) ON CONFLICT (p_code, mog, oem_num, oem_brand) DO UPDATE SET shipment = %{shipment},
          updated_at = %{updated_at},
          va_item_id = %{va_item_id},
          prices = %{prices},
          meta_prices = %{meta_prices},
          count = %{count},
          storehouses = %{storehouses}
      }.freeze

      S_I_ERROR = %Q(Ошибка сохранения товара в базу.
        %{msg}
      ).freeze

      def initialize(
        p_code:       nil,
        i_attrs:      {},
        doc_info:     {}
      )

        super

        @p_code     = p_code
        @doc_info   = doc_info
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

          when 'КоличествоРегион'.freeze then
            start_parse_storehouse

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

          when 'АртикулПроизводителя'.freeze then
            parse_item(:oem_num)

          when 'Артикул'.freeze then
            parse_item(:mog)

          when "Производитель".freeze then
            parse_item(:oem_brand)

          when 'Количество'.freeze then
            parse_item(:count)
            parse_item_storehouse(:count)

          when "КратностьОтгрузки".freeze then
            parse_item(:shipment)

          when 'Наименование'.freeze then
            parse_price(:name)

          when 'ИдТипаЦены'.freeze then
            parse_item_price(:id)

          when 'ЦенаЗаЕдиницу'.freeze then
            parse_item_price(:value)

          when 'КоличествоРегион'.freeze then
            stop_parse_storehouse

          when 'Регион'.freeze then
            parse_item_storehouse(:city)

        end # case

      end # end_element

      private

      def start_parse_storehouse

        @parse_storehouse       = true
        @parse_storehouse_hash  = {}

      end

      def stop_parse_storehouse

        unless @parse_storehouse_hash.empty?
          @item[:storehouses][@parse_storehouse_hash[:city]] = @parse_storehouse_hash[:count].try(:to_i) || 0
        end

        @parse_storehouse       = false
        @parse_storehouse_hash  = {}

      end

      def for_storehouse?
        @parse_storehouse == true
      end

      def parse_item_storehouse(key)

        @parse_storehouse_hash ||= {}
        @parse_storehouse_hash[key] = tag_value if for_storehouse?

      end

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
          p_code:       @p_code,
          prices:       {},
          meta_prices:  {},
          storehouses:  {}
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

        @item[:prices][@item_price[:id]]      = @item_price[:value].try(:to_f) || 0
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

        begin

          sql(ITEM_INSERT_OR_UPDATE % {

            p_code:       quote(@item[:p_code]),
            mog:          quote(@item[:mog].to_s.clean_whitespaces[0..99]),

            oem_num:      quote(@item[:oem_num].to_s.clean_whitespaces[0..99]),
            oem_brand:    quote(@item[:oem_brand].to_s.clean_whitespaces[0..99]),

            shipment:     @item[:shipment].try(:to_i) || 1,
            updated_at:   quote(::Time.now.utc),
            va_item_id:   quote(@item[:id].to_s),
            prices:       quote((@item[:prices] || {}).to_json),
            meta_prices:  quote((@item[:meta_prices] || {}).to_json),
            count:        @item[:count].try(:to_i),
            storehouses:  quote((@item[:storehouses] || {}).to_json)

          })

        rescue => ex

          log(S_I_ERROR % {
            msg: [ex.message].push(ex.backtrace).join("\n")
          })

        end

      end # save_item

      def sql(str)
        ::ApplicationRecord.execute(str)
      end

      def quote(el)
        ::ApplicationRecord.quote(el)
      end

    end # ChelOffers

  end # Parsers

end # VoshodAvtoExchange
