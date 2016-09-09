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
            parse_item_params(:p_item_id)

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

          when "Единица".freeze       then
            parse_item_params(:unit)

          when "Статус".freeze        then
            parse_item_params(:state_name)

          when "АдресДоставки".freeze  then
            parse_item_params(:delivery_address)

          when "ДатаДоставки".freeze  then
            parse_item_params(:delivery_at)

          when "Коэффициент".freeze   then
            parse_item_params(:in_pack)

          when "КодСтранаПроисхождения".freeze    then
            parse_item_params(:contry_code)

          when "СтранаПроисхождения".freeze       then
            parse_item_params(:contry_name)

          when "НомерГТД".freeze      then
            parse_item_params(:gtd)

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

        order = ::Order.where(id: @order_params[:order_id]).first

        unless order

          log(S_ERROR % {
            msg: "Заказ #{@order_params[:order_id]} не найден"
          }) and return

        end

        if @item_params.empty?
          log(P_ERROR % { tag: tag_debug }) and return
        end

        ci = ::CartItem.find_or_initialize_by({
          order_id:   @order_params[:order_id],
          p_item_id:  @item_params[:p_item_id]
        })

        ci.user_id      ||= order.user_id
        ci.p_id         ||= order.p_id

        ci.state_name     = @item_params[:state_name]

        ci.mog            = @item_params[:mog]
        ci.name           = @item_params[:name]
        ci.unit           = @item_params[:unit]
        ci.in_pack        = @item_params[:in_pack]
        ci.contry_code    = @item_params[:contry_code]
        ci.contry_name    = @item_params[:contry_name]
        ci.gtd            = @item_params[:gtd]

        ci.raw_price      = true
        ci.price          = @item_params[:price]
        ci.total_price    = @item_params[:total_price]
        ci.count          = @item_params[:count]

        ci.delivery_address = @item_params[:delivery_address]
        ci.delivery_at      = @item_params[:delivery_at].try(:to_time)

        log(S_ERROR % {
          msg: ci.errors.full_messages
        }) unless ci.upsert

        # Помечаем заказ обоаботанным
        order.set(operation_state: 2) if order.operation_state < 2

        # Обновляем итоговую сумму заказа
        order.set(amount: order.basket_total_price)

      end # save_item

    end # Order < Base

  end # Parsers

end # VoshodAvtoExchange
