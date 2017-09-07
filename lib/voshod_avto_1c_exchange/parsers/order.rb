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

          when "АртикулПроизводителя".freeze  then
            parse_item_params(:oem_num)

          when "Производитель".freeze  then
            parse_item_params(:oem_brand)

          when "КодПоставщика".freeze  then
            parse_item_params(:p_code)

          when "ЦенаЗакупа".freeze then
            parse_item_params(:purchase_price)

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

        # Список изменений товара
        changes_list = []

        begin

          ci = ::CartItem.find_or_initialize_by({

            user_id:      order.user_id,
            order_id:     order.id,

            mog:          @item_params[:mog] || '',

            # Если код поставщика пуст -- используем код по-умочланию
            p_code:       @item_params[:p_code].blank? ? 'VNY6' : @item_params[:p_code],

            # Приводим номер производителя и его название к нужному виду
            oem_num:      ::Cross.clean( (@item_params[:oem_num].try(:clean_whitespaces) || '')[0..99] ),
            oem_brand:    ::VendorAlias.get_name( (@item_params[:oem_brand].try(:clean_whitespaces) || '')[0..99] )

          })

          ci.state_name       = @item_params[:state_name] || ''

          ci.price            = @item_params[:price].try(:to_f) || 0
          ci.total_price      = @item_params[:total_price].try(:to_f) || 0
          ci.count            = @item_params[:count].try(:to_i) || 0

          ci.oem_num_original   = (@item_params[:oem_num].try(:clean_whitespaces) || '')[0..99]
          ci.oem_brand_original = (@item_params[:oem_brand].try(:clean_whitespaces) || '')[0..99]

          # Цена закупа у внешнего поставщика. Пока не будем обновлять эти данные
          # при обмене с 1С
          # ci.purchase_price   = @item_params[:purchase_price].try(:to_f) || 0

          ci.delivery_address = @item_params[:delivery_address] || ''
          ci.delivery_at      = @item_params[:delivery_at].try(:to_time)

          if ci.new_record?

            ci.name       = @item_params[:name] || ''
            ci.va_item_id = @item_params[:va_item_id] || ''

            changes_list  << 'Добавлен новый товар'

          else

            changes_list.concat(
              ::CartItemHistory.changes_for(ci.changes)
            )

          end # if

          if ci.save

            changes_list.each { |msg|

              ::CartItemHistory.add(
                cart_item_id:   ci.id,
                user_name:      'Менеджер',
                msg:            msg
              )

            }

          else

            log(S_ERROR % {
              msg: "#{ci.errors.full_messages}\n#{ci.inspect}"
            })

          end

        rescue ::ActiveRecord::RecordNotUnique
          retry
        rescue => ex

          log(S_ERROR % {
            msg: [ex.message].push(ex.backtrace).join("\n")
          })

        end

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
