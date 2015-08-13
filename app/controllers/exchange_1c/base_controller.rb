# encoding: utf-8
module Exchange_1c

  class BaseController < ::ApplicationController

    unloadable

    before_filter :auth
    skip_before_filter :verify_authenticity_token

    private

    def auth
      true
    end # auth

  end # BaseController

end # Exchange_1c
