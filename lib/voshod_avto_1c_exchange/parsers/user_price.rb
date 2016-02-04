#
# Обработка цен пользователей
#
module VoshodAvtoExchange

  module Parsers

    class UserPrice < Base

      def start_element(name, attrs = [])

        super

        case name

          when  "Контрагент"  then start_parse_params
          when  "ТипЦен"      then start_parse_params
          when  "НоменклатурнаяЦеноваяГруппа" then start_parse_params

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "Контрагент"   then
            stop_parse_params
            save_data

          when "Ид"                   then parse_params(:id)
          when "Наименование"         then parse_params(:name)
          when "Статус"               then parse_params(:state)
          when "Инн"                  then parse_params(:inn)

        end # case

      end # end_element

      private

      def save_data
      end # save_data

    end # UserPrice

  end # Parsers

end # VoshodAvtoExchange
