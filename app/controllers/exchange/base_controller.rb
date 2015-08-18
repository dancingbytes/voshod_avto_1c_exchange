# encoding: utf-8
module Exchange

  class BaseController < ::ApplicationController

    unloadable

#    before_filter :auth
    skip_before_filter :verify_authenticity_token

    layout false

    # GET|POST /exchange/init
    def init

      ::Rails.logger.tagged("/exchange/init") {
        ::Rails.logger.error(params.inspect)
      }

      case params[:mode]
        when 'checkauth'
          render(text: "success\nexchange_1c\n#{rand(9999)}", layout: false) and return
        when 'init'
          render(text: "zip=no\nfile_limit=99999999999999999", layout: false) and return
        else
          render(text: "success", layout: false) and return
      end

    end # index

    private

    def auth

      return true if ::VoshodAvtoExchange::login.nil?

      authenticate_or_request_with_http_basic do |login, password|
        (login == ::VoshodAvtoExchange::login && password == ::VoshodAvtoExchange::password)
      end

    end # auth

  end # BaseController

end # Exchange_1c
