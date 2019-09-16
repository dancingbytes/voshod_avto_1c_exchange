# encoding: utf-8
module VoshodAvtoExchange

  module Exports

    module User

      extend self

      def list(operation_id: nil, doc: true, users_list: nil)

        str           = ""
        first_name    = ""
        last_name     = ""
        date          = Time.now.strftime('%Y-%m-%d')
        time          = Time.now.strftime('%H:%M:%S')
        users_list  ||= ::User.where(operation_state: 0)

        # Выбраем всех пользователей на обработку
        users_list.each { |user|

          # Выставляем индектификатор операции
          user.update_columns(operation_id: operation_id) unless operation_id.blank?

          # Формируем карточку пользователя
          str << ::VoshodAvtoExchange::Template::USER % {

            kid:            user.uid,
            inn:            xml_escape(user.inn),
            user_type:      ::VoshodAvtoExchange::USER_TYPE[user.user_type] || 'Неизвестно',
            date:           date,
            time:           time,
            company:        xml_escape(user.company),
            first_name:     xml_escape(user.first_name),
            last_name:      xml_escape(user.last_name),
            email:          xml_escape(user.login),
            phone:          xml_escape(user.phone),
            contact_person: xml_escape("#{user.last_name} #{user.first_name}")

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

        ::User.where({
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

    end # User

  end # Exports

end # VoshodAvtoExchange
