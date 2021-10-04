# encoding: utf-8
#
# Обработка цен пользователей
#
module VoshodAvtoExchange

  module Parsers

    class Order < Base

      CHANGES_KEYS = {

        state_name:       { type_of: 1, msg: '%{before} → %{after}' },
        delivery_address: { type_of: 2, msg: '%{before} → %{after}' },
        count:            { type_of: 3, msg: '%{before} → %{after}' },
        price:            { type_of: 4, msg: '%{before} руб. → %{after} руб.' },
        name:             { type_of: 6, msg: '%{before} → %{after}' }

      }.freeze

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
          
          when "ОбъединенаВ".freeze        then
            parse_item_params(:info)

          when "АдресДоставки".freeze  then
            parse_item_params(:delivery_address)

          when "ДатаДоставки".freeze  then
            parse_item_params(:delivery_at)

        end # case

      end # end_element

      private

      def start_parse_order
        @order_params = {}
      end

      def start_parse_item
        @item_params  = {}
      end

      def order?
        tag == 'Документ'.freeze
      end

      def item?
        tag == 'Товар'.freeze
      end

      def parse_order_params(name)
        @order_params[name] = tag_value if order?
      end

      def parse_item_params(name)
        @item_params[name]  = tag_value if item?
      end

      def save_item
        order = ::Order.where(uid: @order_params[:order_id]).take

        # Заказ не найден -- завершаем работу
        return if order.nil?

        # Параметры товара пусты -- пишем в лог и завершаем работу
        if @item_params.empty?
          log(P_ERROR % { tag: tag_debug }) and return
        end

        # Количество попыток
        retry_tries  = 5
        # cart_items = []

        begin
          # Список изменений товара
          changes_list = []

          # puts Item.count
          ci = find_item_by(order, @item_params)
          # cart_items << ci

          item = ci.item

          item.mog              = @item_params[:mog].to_s
          # Если код поставщика пуст -- используем код по-умочланию
          item.p_code           = 'VNY6'
          # Приводим номер производителя и его название к нужному виду
          item.oem_num          = ::CrossModule.clean(@item_params[:oem_num].to_s.squish[0..99])
          item.oem_brand        = ::VendorAliasModule.clean(@item_params[:oem_brand].to_s.squish[0..99])

          ci.state_name       = @item_params[:state_name] || ''
          ci.price            = @item_params[:price].try(:to_f) || 0
          ci.count            = @item_params[:count].try(:to_i) || 0
          ci.delivery_address = @item_params[:delivery_address] || ''
          ci.delivery_at      = @item_params[:delivery_at].try(:to_time)

          if item.new_record?
            item.name       = @item_params[:name].to_s
            item.va_item_id = @item_params[:va_item_id].to_s

            changes_list  << { type_of: 5, msg: 'Добавлен новый товар' }
          else
            changes_list.concat(
              changes_for(ci.changes)
            )
          end

          ::CartItem.transaction(requires_new: true) do
            if ci.save(validate: false) && item.save(validate: false)
              changes_list.each do |el|
                ::CartItemHistoryModule.add(
                  cart_item_id: ci.id,
                  type_of: el[:type_of],
                  user_name: 'Менеджер',
                  msg: el[:msg]
                )
              end
            end
          end # transaction
        rescue ::ActiveRecord::RecordNotUnique,
               ::PG::UniqueViolation,
               ::PG::TRDeadlockDetected

          retry_tries = retry_tries - 1
          retry if retry_tries > 0
        rescue => ex
          log(S_ERROR % {
            msg: [ex.message].push(ex.backtrace).join("\n")
          })
          Raven.capture_exception(ex)
        end

        # Если позиции не пришли в файле, значит они удалены в 1С
        # order.cart_items.where.not(id: cart_items.map(&:id)).destroy_all

        # Помечаем заказ обоаботанным и
        # обновляем итоговую сумму заказа
        order.update_columns({
          operation_state:  2,
          amount:           total_price_for(order.id)
        })

        # Обновление статуса заказа
        ::Order::UpdateStatus.call(order: order)
      end # save_item

      def find_item_by(order, params)
        va_item_id = params[:va_item_id].to_s

        if va_item_id.present?
          ci = order.cart_items.joins(:item).where(items: { va_item_id: va_item_id }).take
        end

        return ci if ci

        item = ::Item.find_or_initialize_by(
          mog:          params[:mog].to_s,
           # Если код поставщика пуст -- используем код по-умочланию
          p_code:       params[:p_code].blank? ? 'VNY6' : params[:p_code],

          # Приводим номер производителя и его название к нужному виду
          oem_num:      ::CrossModule.clean(params[:oem_num].to_s.squish[0..99]),

          oem_brand:    ::VendorAliasModule.clean(params[:oem_brand].to_s.squish[0..99])
        )

        order.cart_items.find_or_initialize_by(item: item)
      end # find_item_by

      def changes_for(changes)

        CHANGES_KEYS.inject([]) { |arr, (key, hash)|

          if (el = changes[key])

            arr << {
              type_of: hash[:type_of],
              msg:     (hash[:msg] % { before: el[0], after: el[1] })
            }

          end
          arr

        }

      end

      def total_price_for(order_id)

        ::CartItem.
          where(order_id: order_id).
          sum("cart_items.price * cart_items.count")

      end

    end # Order < Base

  end # Parsers

end # VoshodAvtoExchange
