# encoding: utf-8
#
# Обработка торговых точек
#
module VoshodAvtoExchange

  module Parsers

    class Outlet < Base

      def start_element(name, attrs = [])

        super

        case name
          when "ТорговаяТочка".freeze then 
            start_parse_params
        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "ИД_Контрагент".freeze then parse_user_id(:user_id)
          when "Адрес".freeze then parse_params(:address)
          when "ГУИД".freeze then parse_params(:guid)
          when "Статус".freeze then parse_params(:status)
          when "ГУИД_РД".freeze then parse_delivery_area_id(:delivery_area_id)
          when "ТорговаяТочка".freeze then save_outlet

        end # case

      end # end_element

      private

      def start_parse_params
        @params = {}
      end # start_parse_params

      def parse_params(name)
        @params[name] = tag_value
      end # parse_params

      def parse_delivery_area_id(name)
        @params[name] = ::DeliveryArea.find_by(guid: tag_value).try(:id)
      end

      def parse_user_id(name)
        @params[name] = ::User.find_by(uid: tag_value).try(:id)
      end

      def save_outlet
        ::Outlet::UpdateOrCreate.call(params: @params).success?
      end

    end # Outlet

  end # Parsers

end # VoshodAvtoExchange
