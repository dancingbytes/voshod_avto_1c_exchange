# encoding: utf-8
module Exchange_1c

  class OrdersController < ApplicationController

    unloadable

#    before_filter :auth
    skip_before_filter :verify_authenticity_token



  end # OrdersController

end # Exchange_1c
