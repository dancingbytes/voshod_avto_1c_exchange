#
# Обработка регистраций пользователей
#
module VoshodAvtoExchange

  module Parsers

    class UserReg < Base

      P_ERROR = %Q(Ошибка парсинга.\n%{tag}).freeze
      F_ERROR = %Q(Клиент не найден.\n%{pr}).freeze

      S_ERROR = %Q(Ошибка сохранения правил цен в базе.
        %{msg}
      ).freeze

      N_ERROR = %Q(Ошибка разбора параметров.
        ИД клиента: %{usr}
        %{msg}
      ).freeze

      ACCEPTED = 'Утвержден'.freeze
      REJECTED = 'Отклонен'.freeze
      IDLE     = 'Отложен'.freeze

      def start_element(name, attrs = [])

        super

        case name

          when "РегистрацияКлиентов".freeze then start_parse_params

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "РегистрацияКлиентов".freeze  then save_data
          when "Ид".freeze                   then parse_params(:id)
          when "Наименование".freeze         then parse_params(:name)
          when "Статус".freeze               then parse_params(:state)
          when "Инн".freeze                  then parse_params(:inn)

        end # case

      end # end_element

      private

      def start_parse_params
        @params = {}
      end # start_parse_params

      def parse_params(name)
        @params[name] = tag_value
      end # parse_params

      def params
        @params || {}
      end # params

      def save_data

        if params.empty?
          log(P_ERROR % { tag: tag_debug }) and return
        end

        usr = ::User.where(id: params[:id]).first

        unless usr
          log(F_ERROR % { pr: params.inspect }) and return
        end

        # Разбор параметров регистарции
        case params[:state]

          # Одобрили регистрацию
          when ACCEPTED then

            usr.approve_state   = 1
            usr.operation_state = 2
            usr.inn             = params[:inn] unless params[:inn].nil?

          # Отклонили в регистрации
          when REJECTED then

            usr.approve_state   = 2
            usr.operation_state = 2

          # Регистрация отложена
          when IDLE then

            usr.approve_state   = 0
            usr.operation_state = 0

          # Если статус не понятен -- тоже отклоняем.
          else

            usr.approve_state   = 2
            usr.operation_state = 2

            log(N_ERROR % {
              msg: "Значение параметра [state: #{params[:state]}] неизвестно",
              usr: usr.id.to_s
            })

        end # case

        begin

          usr.save(validate: false)

          # Отправляем результат проверки регистрации
          if usr.approved?
            # Если пользователю подтверждена регистрация
            usr.send_approve_request
          elsif usr.rejected?
            # Если отказали
            usr.send_reject_request
          end

        rescue => ex

          log(S_ERROR % {
            msg: [ex.message].push(ex.backtrace).join("\n")
          })

        end

      end # save_data

    end # UserReg

  end # Parsers

end # VoshodAvtoExchange
