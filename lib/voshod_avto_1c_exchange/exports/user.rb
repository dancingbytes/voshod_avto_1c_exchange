module VoshodAvtoExchange

  module Exports

    module User

      extend self

      USER_TYPE = {
        0   =>  'ИП',
        1   =>  'ООО',
        2   =>  'ОАО',
        3   =>  'ЗАО',
        4   =>  'ЧастноеЛицо'
      }.freeze

      def list(operation_id = 0, doc: true)

        str         = ""
        first_name  = ""
        last_name   = ""
        date        = Time.now.strftime('%Y-%m-%d')
        time        = Time.now.strftime('%H:%M:%S')

        # Выбраем всех пользователей на обработку
        ::User.where(operation_state: 0).each { |user|

          # Выставляем индектификатор операции
          user.update_columns(operation_id: operation_id)

          # Формируем карточку пользователя
          str << ::VoshodAvtoExchange::Template::USER % {

            kid:            user.uid,
            inn:            xml_escape(user.inn),
            user_type:      USER_TYPE[user.user_type] || 'Неизвестно',
            date:           date,
            time:           time,
            company:        xml_escape(user.company),
            first_name:     xml_escape(user.first_name),
            last_name:      xml_escape(user.last_name),
            email:          xml_escape(user.login),
            phone:          xml_escape(user.phone),
            contact_person: xml_escape(user.contact_person)

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
