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
          when "РайонДоставки".freeze then
            @level = 1
            @area_params = {}
            @periods = []
          when "ДеньНедели".freeze then 
            @level = 2
            @day_params = {}
          when "ПериодДоставки".freeze then
            @level = 3
            @period_params = {}
        end # case

      end # start_element

      def end_element(name)

        super

        case name
          when "Наименование".freeze then
            parse_area_params(:title)         if @level==1
            parse_day_params(:day_of_week)    if @level==2
            parse_period_params(:period)      if @level==3
          when "ГУИД".freeze then
            parse_area_params(:guid)    if @level==1
            parse_guid_period_params()  if @level==3
          when "ПометкаУдаления".freeze then destroy_area
          when "ПериодДоставки".freeze then
            @level = 2
            save_period
          when "ДеньНедели".freeze then @level = 1
          when "РайонДоставки".freeze then save_area
        end # case

      end # end_element

      private

      def parse_area_params(name)
        @area_params[name] = tag_value
      end
      
      def parse_day_params(name)
        @day_params[name] = tag_value
      end

      def parse_period_params(name)
        @period_params[name] = tag_value
      end

      # создаем уникальный гуид как день недели + 1с гуид
      # чтобы потом по нему писать изменения ПД
      def parse_guid_period_params
        @period_params[:guid] = @day_params[:day_of_week] + '-' + tag_value
      end

      # Удаляем РД если есть пометка на удаление
      def destroy_area
        ::DeliveryArea::Destroy.call(params: @area_params).success? if tag_value == 'true'
      end

      def save_period
        @period_params.merge!({ :day_of_week => @day_params[:day_of_week] })
        @periods << @period_params
      end
      
      def save_area

        # обновляем или создаем РД
        area_result = ::DeliveryArea::UpdateOrCreate.call(params: @area_params)
        
        # запоминаем старые записи ПД
        old_delivery_periods_guids = area_result.delivery_periods.pluck(:guid) if area_result.delivery_periods

        # обновляем/создаем пришедшие ПД
        period_results = true

        @periods.each do |period|
          period_result = ::DeliveryPeriod::UpdateOrCreate.call(
            params: period.merge(delivery_area_id: area_result.delivery_area.id)
          )
          period_results = period_results && period_result.success?
        end
        
        new_delivery_periods_guids = area_result.delivery_periods.pluck(:guid) if area_result.delivery_periods
        
        # удаляем "лишние" ПД (которых нет в файле)
        clean_results = true

        (old_delivery_periods_guids.to_a - new_delivery_periods_guids.to_a).each do |guid|
          clean_result = DeliveryArea::Destroy.call(params: {guid: guid})
          clean_results = clean_results && clean_result.success?
        end

        # true - все прошло ок
        area_result.success? && period_results && clean_results

      end

    end # DeliveryArea

  end # Parsers

end # VoshodAvtoExchange
