require 'nokogiri'

module VoshodAvtoExchange

  def login(v = nil)

    @login = v unless v.blank?
    @login

  end # login

  def password(v = nil)

    @pass = v unless v.blank?
    @pass

  end # password

  alias :pass :password

end # VoshodAvtoExchange

require 'voshod_avto_1c_exchange/version'

if defined?(::Rails)
  require 'voshod_avto_1c_exchange/engine'
  require 'voshod_avto_1c_exchange/railtie'
end
