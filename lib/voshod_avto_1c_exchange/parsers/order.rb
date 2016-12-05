#
# Обработка цен пользователей
#
module VoshodAvtoExchange

  module Parsers

    class Order < Base

      P_ERROR = %Q(Ошибка парсинга.\n%{tag}).freeze

      S_ERROR = %Q(Ошибка сохранения информации по номенклатуре заказа в базе.
        %{msg}
      ).freeze

      def start_element(name, attrs = [])

        super

        case name

          when "Документ".freeze  then
            start_parse_order

          when "Товар".freeze     then
            start_parse_item

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "Товар".freeze         then
            save_item

          when "Ид".freeze            then
            parse_order_params(:order_id)
            parse_item_params(:va_item_id)

          when "Артикул".freeze       then
            parse_item_params(:mog)

          when "Наименование".freeze  then
            parse_item_params(:name)

          when "ЦенаЗаЕдиницу".freeze then
            parse_item_params(:price)

          when "Количество".freeze    then
            parse_item_params(:count)

          when "Сумма".freeze         then
            parse_item_params(:total_price)

          when "Статус".freeze        then
            parse_item_params(:state_name)

          when "АдресДоставки".freeze  then
            parse_item_params(:delivery_address)

          when "ДатаДоставки".freeze  then
            parse_item_params(:delivery_at)

        end # case

      end # end_element

      private

      def start_parse_order
        @order_params = {}
      end # start_parse_order

      def start_parse_item
        @item_params  = {}
      end # start_parse_item

      def order?
        tag == 'Документ'.freeze
      end # order?

      def item?
        tag == 'Товар'.freeze
      end # item?

      def parse_order_params(name)
        @order_params[name] = tag_value if order?
      end # parse_order_params

      def parse_item_params(name)
        @item_params[name]  = tag_value if item?
      end # parse_item_params

      def save_item

        order = ::Order.where(uid: @order_params[:order_id]).first

        unless order

          log(S_ERROR % {
            msg: "Заказ #{@order_params[:order_id]} не найден"
          }) and return

        end

        if @item_params.empty?
          log(P_ERROR % { tag: tag_debug }) and return
        end

        ci = ::CartItem.find_or_initialize_by({
          order_id:     order.id,
          va_item_id:   @item_params[:va_item_id]
        })

        ci.state_name       = @item_params[:state_name]

        #
        # TODO:
        # Основная проблема возникнет при обработке товаров внещних поставщиков
        #
        if ci.new_record?

          ci.user_id  = order.user_id
          ci.p_code   = ::VoshodAvtoExchange::P_CODE
          ci.mog      = @item_params[:mog]
          ci.name     = @item_params[:name]

          item = ::Item.where(
            p_code:      ::VoshodAvtoExchange::P_CODE,
            va_item_id:  @item_params[:va_item_id]
          ).limit(1).to_a[0]

          if item

            ci.oem_num    = item.oem_num
            ci.oem_brand  = item.oem_brand

          end # if

        end # if



        ci.raw_price        = true
        ci.price            = @item_params[:price].try(:to_f) || 0
        ci.total_price      = @item_params[:total_price].try(:to_f) || 0
        ci.count            = @item_params[:count].try(:to_i) || 0

        ci.delivery_address = @item_params[:delivery_address]
        ci.delivery_at      = @item_params[:delivery_at].try(:to_time)

        log(S_ERROR % {
          msg: ci.errors.full_messages
        }) unless ci.save

        # Помечаем заказ обоаботанным и
        # обновляем итоговую сумму заказа
        order.update_columns({
          operation_state:  2,
          amount:           order.basket_total_price
        })

      end # save_item

    end # Order < Base

  end # Parsers

end # VoshodAvtoExchange
