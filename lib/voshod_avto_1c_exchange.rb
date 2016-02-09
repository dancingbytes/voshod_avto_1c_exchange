require 'logger'
require 'fileutils'
require 'nokogiri'
require 'zip'

module VoshodAvtoExchange

  extend self

  LOG_F = %Q([%{time}] %{name}\n%{msg}).freeze

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

  def run(file_lock = ::File.join(::Rails.root, "tmp", 'voshod_avto_1c_exchange.lock'))

    begin
      f = ::File.new(file_lock, ::File::RDWR|::File::CREAT, 0400)
      return if f.flock(::File::LOCK_EX) === false
    rescue ::Errno::EACCES
      return
    end

    begin
      ::VoshodAvtoExchange::Manager.run
    rescue => ex
      log ex.inspect
    ensure
      ::FileUtils.rm(file_lock, force: true)
    end

  end # run

  def import_dir(v = nil)

    @import_dir = v unless v.blank?
    @import_dir ||= ::File.join(::Rails.root, "tmp", "exchange_1c")

    ::FileUtils.mkdir_p(@import_dir) unless ::FileTest.directory?(@import_dir)

    @import_dir

  end # import_dir

  def log_dir(v = nil)

    @log_dir = v unless v.blank?
    @log_dir ||= ::File.join(::Rails.root, "log")

    ::FileUtils.mkdir_p(@log_dir) unless ::FileTest.directory?(@log_dir)

    @log_dir

  end # log_dir

  def log(msg = "", name = "")

    create_logger unless @logger

    @logger << (LOG_F % {
      time:   ::Time.now,
      name:   name,
      msg:    msg
    }) if @logger

    msg

  end # log

  def close_logger

    return unless @logger
    @logger.close
    @logger = nil

  end # close_logger

  def humanize_time(secs)

    [
      [60,    :сек],
      [60,    :мин],
      [24,    :ч],
      [1000,  :д]
    ].freeze.map { |count, name|

      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end

    }.compact.reverse.join(' ')

  end # humanize_time

  private

  def create_logger

    return if @logger

    log_file = ::File.open(
      ::File.join(::VoshodAvtoExchange::log_dir, "voshod_avto_exchange.log"),
      ::File::WRONLY | ::File::APPEND | ::File::CREAT
    )
    log_file.sync = true
    @logger = ::Logger.new(log_file, 'weekly')
    @logger

  end # create_logger

end # VoshodAvtoExchange

require 'voshod_avto_1c_exchange/version'

require 'voshod_avto_1c_exchange/template'
require 'voshod_avto_1c_exchange/export'

require 'voshod_avto_1c_exchange/parser'
require 'voshod_avto_1c_exchange/manager'

if defined?(::Rails)
  require 'voshod_avto_1c_exchange/engine'
  require 'voshod_avto_1c_exchange/railtie'
end
