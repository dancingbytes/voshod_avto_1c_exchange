# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  # Exchange_1c
  namespace :exchange_1c do

    get  'users'    => 'base#init'
    post 'users'    => 'users#list'

    get  'orders'   => 'base#init'
    post 'orders'   => 'orders#list'

  end # exchange_1c

end # draw
