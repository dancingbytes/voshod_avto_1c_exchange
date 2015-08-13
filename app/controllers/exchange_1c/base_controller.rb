# encoding: utf-8
module Exchange_1c

  class BaseController < ::ApplicationController

    unloadable

    before_filter :auth
    skip_before_filter :verify_authenticity_token

    private

    def auth

      return true if ::VoshodAvtoExchange::login.nil?

      authenticate_or_request_with_http_basic do |login, password|
        (login == ::VoshodAvtoExchange::login && password == ::VoshodAvtoExchange::password)
      end

    end # auth

  end # BaseController

end # Exchange_1c
