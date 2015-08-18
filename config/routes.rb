# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  # Exchange
  namespace :exchange do

    get  'init'     => 'base#init'

    get  'users'    => 'base#init'
    post 'users'    => 'users#list'

    get  'orders'   => 'base#init'
    post 'orders'   => 'orders#list'

  end # exchange

end # draw
