# encoding: utf-8
#
# Обработка кроссов из 1С Восход-авто
#
module VoshodAvtoExchange

  module Parsers

    class ChelCross < Base

      def start_element(name, attrs = [])

        super

        case name

          when  "Деталь".freeze     then
            start_parse

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "Деталь".freeze      then
            stop_parse

          when "НомерДетали".freeze then
            parse_cross(:oem_num)

          when "Бренд".freeze       then
            parse_cross(:oem_brand)

          when "НомерЗамены".freeze then
            parse_cross(:repl_num)

          when "БрендЗамены".freeze then
            parse_cross(:repl_brand)

          when "НазваниеДетали".freeze then
            parse_cross(:repl_name)

          when "Сервис".freeze      then
            parse_cross(:service)

        end # case

      end # end_element

      private

      def start_parse

        @cross        = {}
        @start_parse  = true

      end # start_parse

      def cross?
        @start_parse == true
      end # cross?

      def parse_cross(name)
        @cross[name] = tag_value if cross?
      end # parse_cross

      def stop_parse

        return if @cross.empty?

        ::CrossModule.create_cross(
          oem_num:      @cross[:oem_num],
          oem_brand:    @cross[:oem_brand],
          repl_num:     @cross[:repl_num],
          repl_brand:   @cross[:repl_brand],
          repl_name:    @cross[:repl_name],
          rate:         1,
          service:      @cross[:service],
          reverse:      true
        )

        @cross        = {}
        @start_parse  = false

      end # stop_parse

    end # ChelCross

  end # Parsers

end # VoshodAvtoExchange
