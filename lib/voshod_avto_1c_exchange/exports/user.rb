module VoshodAvtoExchange

  module Exports

    module User

      extend self

      def list(operation_id = 0, doc: true)

        str         = ""
        first_name  = ""
        last_name   = ""
        date        = Time.now.strftime('%Y-%m-%d')
        time        = Time.now.strftime('%H:%M:%S')

        # Выбраем всех пользователей на обработку
        ::User.where(operation_state: 0).each { |user|

          # Выставляем индектификатор операции
          user.set({ operation_id: operation_id })

          # Имя пользователя
          last_name, first_name, _ = user.contact_person.split(/\s/)

          # Формируем карточку пользователя
          str << ::VoshodAvtoExchange::Template::USER % {

            kid:            user.id.to_s,
            inn:            user.inn,
            date:           date,
            time:           time,
            company:        user.company,
            first_name:     first_name,
            last_name:      last_name,
            address:        user.address,
            postcode:       "",
            city:           "",
            street:         "",
            email:          user.email,
            phone:          user.phone,
            contact_person: user.contact_person

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

        res = ::User.where({
          operation_state: 0,
          operation_id:    operation_id
        }).update_all({
          operation_state: 1
        })

        res.modified_count > 0

      end # verify

    end # User

  end # Exports

end # VoshodAvtoExchange
