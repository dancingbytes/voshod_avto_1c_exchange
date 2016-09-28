module VoshodAvtoExchange

  module Exports

    module Order

      extend self

      def list(operation_id = 0, doc: true)

        str   = ""
        date  = Time.now.strftime('%Y-%m-%d')
        time  = Time.now.strftime('%H:%M:%S')

        # Выбраем все заказы на обработку
        ::Order.where(operation_state: 0).each { |order|

          # Выбираем все товары из заказа
          items = order.cart_items.inject("") { |cistr, cart_item|

            cistr << ::VoshodAvtoExchange::Template::ORDER_ITEM % {

              item_id:          cart_item.p_item_id.to_s,
              item_mog:         cart_item.oem_num,
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
          order.set({ operation_id: operation_id })

          # Формируем даныне по доставке
          delivery_address = "",
          delivery_type    = "Самовывоз"

          if order.delivery_type == 1
            delivery_address = order.delivery_address
            delivery_type    = "Доставка"
          end

          # Формируем заказ
          str << ::VoshodAvtoExchange::Template::ORDER % {

            kid:              order.id.to_s,
            date:             order.created_at.strftime('%Y-%m-%d'),
            time:             order.created_at.strftime('%H:%M:%S'),
            price:            order.amount,
            uid:              order.user_id.to_s,
            company:          xml_escape( order.user.try(:company) ),
            full_company:     xml_escape( order.user.try(:full_company) ),

            items:            items,

            payment_date:     date,
            number_1c:        "",
            data_1c:          date,
            detete_1c:        false,
            hold_on_1c:       false,

            comment:          xml_escape(order.comment),
            delivery_address: xml_escape(delivery_address),
            delivery_type:    xml_escape(delivery_type)

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

        res = ::Order.where({
          operation_state: 0,
          operation_id:    operation_id
        }).update_all({
          operation_state: 1
        })

        res.modified_count > 0

      end # verify

      private

      def xml_escape(str)
        ::VoshodAvtoExchange::Util.xml_escape(str)
      end # xml_escape

    end # Order

  end # Exports

end # VoshodAvtoExchange
