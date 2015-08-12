# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  # Exchange_1c
  namespace :exchange_1c do

    get  'orders'      => 'orders#list'
    post 'orders'      => 'orders#save_file'

  end # exchange_1c

end # draw
