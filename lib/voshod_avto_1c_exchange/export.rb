require 'voshod_avto_1c_exchange/exports/user'
require 'voshod_avto_1c_exchange/exports/order'

module VoshodAvtoExchange

  module Exports

    extend self

    # Выборка пользователей и заказов в 1С
    def users_and_orders(operation_id = 0)

      date    = Time.now.strftime('%Y-%m-%d')
      time    = Time.now.strftime('%H:%M:%S')
      str     = ""

      # Выбираем все заказы
      str     << ::VoshodAvtoExchange::Exports::Order.list(operation_id, doc: false)

      # Выбираем всех пользователей на регистрацию
      str     << ::VoshodAvtoExchange::Exports::User.list(operation_id, doc: false)

      ::VoshodAvtoExchange::Template::XML_BASE % {
        date: date,
        time: time,
        body: str
      }

    end # users_and_orders

    def users_and_orders_verify(operation_id = 0)

      ::VoshodAvtoExchange::Exports::User.verify(operation_id)
      ::VoshodAvtoExchange::Exports::Order.verify(operation_id)
      nil

    end # users_and_orders_verify

  end # Exports

end # VoshodAvtoExchange
