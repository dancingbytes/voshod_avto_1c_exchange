# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  get   'exchange' => 'exchange#get',   format: false
  post  'exchange' => 'exchange#post',  format: false

end # draw
