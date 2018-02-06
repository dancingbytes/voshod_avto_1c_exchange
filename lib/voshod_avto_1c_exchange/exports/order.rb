module VoshodAvtoExchange

  module Exports

    module Order

      extend self

      def list(operation_id: nil, doc: true, orders_list: nil)

        str           = ""
        date          = Time.now.strftime('%Y-%m-%d')
        time          = Time.now.strftime('%H:%M:%S')
        orders_list ||= ::Order.where(operation_state: 0)

        # Исключаем заказы тестового пользователя
        orders_list = orders_list.where.not(user_id: 3115)

        # Выбраем все заказы на обработку
        orders_list.each { |order|

          # Выбираем все товары из заказа
          items = order.cart_items.inject("") { |cistr, cart_item|

            cistr << ::VoshodAvtoExchange::Template::ORDER_ITEM % {

              # ИД товара в 1С Восход-авто
              item_id:          xml_escape(cart_item.va_item_id),

              # Код внешнего поставщика
              p_code:           xml_escape(cart_item.p_code),

              # Бренд детали (Производитель)
              oem_brand:        xml_escape(cart_item.oem_brand_original),

              # Номер детали (Артикул производителя)
              oem_num:          xml_escape(cart_item.oem_num_original),

              # Артикул товара в 1С Восход-авто
              item_mog:         xml_escape(cart_item.mog),

              # Цена закупа (у внешнего поставщика)
              purchase_price:   cart_item.purchase_price || 0,

              item_name:        xml_escape(cart_item.name),
              item_contry_code: "643",
              item_contry_name: "РОССИЯ",
              item_gtd:         "",
              item_price:       cart_item.price,
              item_count:       cart_item.count,
              item_total:       cart_item.total_price

            }
            cistr

          } # items

          # Если корзина заказа пуста -- пропускаем этот заказ
          next if items.blank?

          # Выставляем индектификатор операции
          order.update_columns(operation_id: operation_id) unless operation_id.blank?

          # Формируем даныне по доставке
          if order.delivery_type == 1
            d_address = order.delivery_address
            d_type    = "Доставка"
          else
            d_address = ""
            d_type    = "Самовывоз"
          end

          # Формируем заказ
          str << ::VoshodAvtoExchange::Template::ORDER % {

            kid:              order.uid,
            date:             order.created_at.strftime('%Y-%m-%d'),
            time:             order.created_at.strftime('%H:%M:%S'),
            price:            order.amount,
            uid:              order.user_uid,
            company:          xml_escape( order.user.try(:company) ),
            full_company:     xml_escape( order.user.try(:full_company) ),

            user_type:        ::VoshodAvtoExchange::USER_TYPE[order.user.try(:user_type)] || 'Неизвестно',

            items:            items,

            payment_date:     date,
            number_1c:        "",
            data_1c:          date,
            detete_1c:        false,
            hold_on_1c:       false,

            comment:          xml_escape(order.comment),
            delivery_address: xml_escape(d_address),
            delivery_type:    xml_escape(d_type)

          }

        } # each

        # Итоговый документ
        doc ? (::VoshodAvtoExchange::Template::XML_BASE % {
          date: date,
          time: time,
          body: str
        }) : str

      end # list

      # Закрываем экспорт
      def verify(operation_id = 0)

        ::Order.where({
          operation_state: 0,
          operation_id:    operation_id
        }).update_all({
          operation_state: 1
        })

      end # verify

      private

      def xml_escape(str)
        ::VoshodAvtoExchange::Util.xml_escape(str)
      end # xml_escape

    end # Order

  end # Exports

end # VoshodAvtoExchange
