module VoshodAvtoExchange

  module Exports

    module Order

      extend self

      def export

        %q(<?xml version="1.0" encoding="windows-1251"?>
  <КоммерческаяИнформация ВерсияСхемы="2.05" ДатаФормирования="2015-08-18T12:49:00" ФорматДаты="ДФ=yyyy-MM-dd; ДЛФ=DT" ФорматВремени="ДФ=ЧЧ:мм:сс; ДЛФ=T" РазделительДатаВремя="T" ФорматСуммы="ЧЦ=18; ЧДЦ=2; ЧРД=." ФорматКоличества="ЧЦ=18; ЧДЦ=2; ЧРД=.">
  </КоммерческаяИнформация>).freeze

      end # export

    end # Order

  end # Exports

end # VoshodAvtoExchange
