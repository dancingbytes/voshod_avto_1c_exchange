# encoding: utf-8
VoshodAvtoExchange::Engine.routes.draw do

  match 'exchange' => 'exchange#init', via: [:get, :post, :put]

end # draw
