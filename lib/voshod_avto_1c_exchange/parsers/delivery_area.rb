# encoding: utf-8
#
# Обработка регионов доставки
#
module VoshodAvtoExchange

  module Parsers

    class DeliveryArea < Base

      def start_element(name, attrs = [])

        super

        case name
          when "РайонДоставки".freeze then start_parse_params
        end # case

      end # start_element

      def end_element(name)

        super

        case name
          when "Наименование".freeze then parse_params(:title)
          when "ГУИД".freeze then parse_params(:guid)
          when "ПометкаУдаления".freeze then parse_params(:deleted)
          when "ПериодДоставки".freeze then parse_params(:period)
          when "ПериодДоставки_ГУИД".freeze then parse_params(:guid)
          when "ДеньНедели".freeze then parse_params(:day_of_week)
          when "РайонДоставки".freeze then ::DeliveryArea::Create.call(params: @params)
        end # case

      end # end_element

      private

      def start_parse_params
        @params = {}
      end # start_parse_params

      def parse_params(name)
        @params[name] = tag_value
      end # parse_params
    
    end # DeliveryArea

  end # Parsers

end # VoshodAvtoExchange
