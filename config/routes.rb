# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  # Exchange_1c
  namespace :exchange_1c do

    post 'users'    => 'users#list'
    post 'orders'   => 'orders#list'

  end # exchange_1c

end # draw
