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
          when "Наименование".freeze then parse_area_params(:title)
          when "ГУИД".freeze then parse_area_params(:guid)
          when "ПометкаУдаления".freeze then parse_area_params(:deleted)
          when "ПериодДоставки".freeze then parse_period_params(:period)
          when "ПериодДоставки_ГУИД".freeze then parse_period_params(:guid)
          when "ДеньНедели".freeze then parse_period_params(:day_of_week)
          when "РайонДоставки".freeze then save
        end # case

      end # end_element

      private

      def start_parse_params
        @area_params = {}
        @period_params = {}
      end # start_parse_params

      def parse_area_params(name)
        @area_params[name] = tag_value
      end # parse_area_params
      
      def parse_period_params(name)
        @period_params[name] = tag_value
      end # parse_area_params

      def save
        pp '-----save----------'

        area_result = ::DeliveryArea::UpdateOrCreate.call(params: @area_params)

        # pp area_result.delivery_area

        @period_params.merge!(delivery_area_id: area_result.delivery_area.id)
pp @period_params        
        period_result = ::DeliveryPeriod::UpdateOrCreate.call(params: @period_params)

        # pp period_result.delivery_period

        area_result.success? && period_result.success?

      end

    end # DeliveryArea

  end # Parsers

end # VoshodAvtoExchange
