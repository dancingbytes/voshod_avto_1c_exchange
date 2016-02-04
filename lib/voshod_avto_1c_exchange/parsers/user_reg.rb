#
# Обработка регистраций пользователей
#
module VoshodAvtoExchange

  module Parsers

    class UserReg < Base

      def start_element(name, attrs = [])

        super

        case name

          when "РегистрацияКлиентов" then start_parse_params

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "РегистрацияКлиентов"  then
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

        if params.empty?
          log "[РегистрацияКлиентов] Ошибка парсинга. #{tag_debug}"
          return
        end

        usr = ::User.where(id: @parse_params[:id]).first

        unless usr
          log "[РегистрацияКлиентов] Клиент не найден. #{params.inspect}"
          return
        end

        puts "--> #{params}"

        # Одобрили регистрацию
        if params[:state] == "Утвержден"

          usr.approved  = true
          usr.inn       = params[:inn] unless params[:inn].nil?
          usr.save(validate: false)

        # Отклонили в регистрации
        elsif params[:state] == "Отклонен"

          usr.approved = false
          usr.save(validate: false)

        end

      end # save_data

    end # UserReg

  end # Parsers

end # VoshodAvtoExchange
