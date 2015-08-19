require 'nokogiri'

module VoshodAvtoExchange

  extend self

  def login(v = nil)

    @login = v unless v.blank?
    @login

  end # login

  def password(v = nil)

    @pass = v unless v.blank?
    @pass

  end # password

  alias :pass :password

  def to_1c_id(str)

    uid = str.to_s.ljust(32, '0')
    "#{uid[0,8]}-#{uid[8,4]}-#{uid[12,4]}-#{uid[16,4]}-#{uid[20,12]}"

  end # to_1c_id

  def to_bson_id(str)
    str.gsub(/-/, '')[0, 24]
  end # to_bson_id

end # VoshodAvtoExchange

require 'voshod_avto_1c_exchange/version'
require 'voshod_avto_1c_exchange/user'

if defined?(::Rails)
  require 'voshod_avto_1c_exchange/engine'
  require 'voshod_avto_1c_exchange/railtie'
end
