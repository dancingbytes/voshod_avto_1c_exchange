# encoding: utf-8
class ExchangeController < ::ApplicationController

  unloadable

  before_filter :auth
  skip_before_filter :verify_authenticity_token

  layout false

  # GET /exchange
  def init

    ::Rails.logger.tagged("/exchange") {
      ::Rails.logger.error(params.inspect)
    }

    case params[:mode]

      when 'checkauth'
        render(text: "success\nexchange_1c\n#{rand(9999)}") and return

      when 'init'
        render(text: "zip=no\nfile_limit=99999999999999999") and return

      when 'success'
        render(text: "success") and return

      when 'query'

        case params[:type]

          when 'catalog'
            render(xml: orders, encoding: 'utf-8') and return

          when 'sale'
            render(xml: ::VoshodAvtoExchange::User.export, encoding: 'utf-8') and return

        else
          render(text: "Type `#{params[:type]}` is not found") and return
        end

      else
        render(text: "Mode `#{params[:mode]}` is not found") and return

    end

  end # index

  private

  def orders

    %q(<?xml version="1.0" encoding="windows-1251"?>
<КоммерческаяИнформация ВерсияСхемы="2.05" ДатаФормирования="2015-08-18T12:49:00" ФорматДаты="ДФ=yyyy-MM-dd; ДЛФ=DT" ФорматВремени="ДФ=ЧЧ:мм:сс; ДЛФ=T" РазделительДатаВремя="T" ФорматСуммы="ЧЦ=18; ЧДЦ=2; ЧРД=." ФорматКоличества="ЧЦ=18; ЧДЦ=2; ЧРД=.">
</КоммерческаяИнформация>).freeze

  end # orders

  def auth

    return true if ::VoshodAvtoExchange::login.nil?

    authenticate_or_request_with_http_basic do |login, password|
      (login == ::VoshodAvtoExchange::login && password == ::VoshodAvtoExchange::password)
    end

  end # auth

end # ExchangeController
