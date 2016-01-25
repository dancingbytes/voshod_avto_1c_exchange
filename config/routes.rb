# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  get   'exchange' => 'exchange#get'
  post  'exchange' => 'exchange#post'

end # draw
