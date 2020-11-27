# encoding: utf-8
module VoshodAvtoExchange

  module Exports

    module Outlet

      extend self

      def list(operation_id: nil, doc: true, outlets_ids: nil)

        str          = ""
        address      = ""
        date         = Time.now.strftime('%Y-%m-%d')
        time         = Time.now.strftime('%H:%M:%S')

        outlets_list   = nil
        outlets_list   = ::Outlet.where(id: outlets_ids) if outlets_ids.present?
        outlets_list ||= ::Outlet.where(operation_state: 0)

        # Выбраем все торговые точки на обработку
        outlets_list.each { |outlet|

          # Выставляем индентификатор операции
          outlet.update_columns(operation_id: operation_id) if operation_id.present?

          # Формируем карточку торговой точки
          str << ::VoshodAvtoExchange::Template::OUTLET % {
            
            id:             outlet.id,
            guid:           outlet.guid,
            client_guid:    outlet.user.uid,
            status:         outlet.status,
            address:        xml_escape(outlet.address),
            date:           date,
            time:           time

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

        ::Outlet.where({
          operation_id: operation_id
        }).update_all({
          operation_state: 1
        })

      end # verify

      private

      def xml_escape(str)
        ::VoshodAvtoExchange::Util.xml_escape(str)
      end # xml_escape

    end # Outlet

  end # Exports

end # VoshodAvtoExchange
