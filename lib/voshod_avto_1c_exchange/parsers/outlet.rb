# encoding: utf-8
#
# Обработка торговых точек
#
module VoshodAvtoExchange

  module Parsers

    class Outlet < Base

      # P_ERROR = %Q(Ошибка парсинга.\n%{tag}).freeze
      # F_ERROR = %Q(Торговая точка не найдена.\n%{pr}).freeze

      # S_ERROR = %Q(Ошибка сохранения данных в базе.
      #   %{msg}
      # ).freeze

      # N_ERROR = %Q(Ошибка разбора параметров.
      #   ИД торговой точки: %{outlet_id}
      #   %{msg}
      # ).freeze

      # ACCEPTED = 'Утвержден'.freeze
      # REJECTED = 'Отклонен'.freeze

      def start_element(name, attrs = [])

        super
        # @params = {}
# puts 'start_element', name

        case name
          when "ТорговаяТочка".freeze then start_parse_params
        end # case

      end # start_element


      def end_element(name)

# puts ' end_element', name

        super

        case name

          when "ИД_Контрагент".freeze then parse_params(:user_id)        
          when "Адрес".freeze then parse_params(:address)
          when "ГУИД".freeze then parse_params(:guid)
          when "Статус".freeze then parse_params(:status)
          when "ГУИД_РД".freeze then parse_delivery_area_id(:delivery_area_id)
          when "ТорговаяТочка".freeze then ::Outlet::Create.call(params: @params)

        end # case

        # puts @params

      end # end_element

      private

      def start_parse_params
        @params = {}
      end # start_parse_params

      def parse_params(name)
        @params[name] = tag_value
      end # parse_params

      def parse_delivery_area_id
        @params[name] = DeliveryAera.where(guid: tag_value).take.id
      end

      # def params
      #   @params || {}
      # end

      # def save_data

# pp @params

        # if params.empty?
        #   log(P_ERROR % { tag: tag_debug }) and return
        # end

        # usr = ::User.where(uid: params[:id]).take.try(:decorate)

        # unless usr
        #   log(F_ERROR % { pr: params.inspect }) and return
        # end

        # # Разбор параметров регистарции
        # case params[:state]

        #   # Одобрили регистрацию
        #   when ACCEPTED then

        #     usr.approve_state   = 1
        #     usr.operation_state = 2
        #     usr.inn             = params[:inn] if params[:inn].present?

        #   # Отклонили в регистрации
        #   when REJECTED then

        #     usr.approve_state   = 2
        #     usr.operation_state = 2

        #   # Если статус не понятен -- ничего не делаем.
        #   else

        #     usr.approve_state   = 0
        #     usr.operation_state = 0

        # end # case

        # # Убираем/выставляем ограничения если...
        # usr.constraint = !params[:orders_exists].to_s.downcase.eql?('true')

        # begin

        #   has_changes = usr.approve_state_changed? || usr.operation_state_changed? || false

        #   usr.save(validate: false)

        #   # Если были изменения в статусе -- уведомляем
        #   if has_changes

        #     # Отправляем результат проверки регистрации
        #     if usr.approved?

        #       # Если пользователю подтверждена регистрация
        #       send_approve_request(usr)

        #     elsif usr.rejected?
        #       # Если отказали
        #       send_reject_request(usr, params[:comment].to_s.squish)
        #     end

        #   end # if

        # rescue => ex

        #   log(S_ERROR % {
        #     msg: [ex.message].push(ex.backtrace).join("\n")
        #   })

        # end

      # end # save_data

      # def send_approve_request(user)

      #   begin

      #     user.set_password
      #     user.save

      #     ::UserMailer.approve_mail(user).deliver

      #   rescue ::Exception => err

      #     ::Rails.logger.tagged("[send_approve_request]") {
      #       ::Rails.logger.error(
      #         %Q(Не смог отправить письмо на почту #{user.login})
      #       )
      #       ::Rails.logger.error(err)
      #     }

      #   end

      # end

      # def send_reject_request(user, comment)

      #   begin
      #     ::UserMailer.reject_mail(user, comment).deliver
      #   rescue ::Exception => err

      #     ::Rails.logger.tagged("[send_reject_request]") {
      #       ::Rails.logger.error(
      #         %Q(Не смог отправить письмо на почту #{user.login})
      #       )
      #       ::Rails.logger.error(err)
      #     }

      #   end

      # end

    end # Outlet

  end # Parsers

end # VoshodAvtoExchange
