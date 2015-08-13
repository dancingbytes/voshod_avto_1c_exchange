require 'nokogiri'

module VoshodAvtoExchange

end # VoshodAvtoExchange

require 'voshod_avto_1c_exchange/version'

if defined?(::Rails)
  require 'voshod_avto_1c_exchange/engine'
  require 'voshod_avto_1c_exchange/railtie'
end
