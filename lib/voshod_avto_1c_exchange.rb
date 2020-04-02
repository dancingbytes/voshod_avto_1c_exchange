# encoding: utf-8
require 'logger'
require 'fileutils'
require 'nokogiri'
require 'zip'
require 'base64'

module VoshodAvtoExchange

  extend self

  TAG     = 'VoshodAvtoExchange'.freeze
  P_CODE  = 'VNY6'.freeze

  USER_TYPE = {
    0   =>  'ИП',
    1   =>  'ООО',
    2   =>  'ОАО',
    3   =>  'ЗАО',
    4   =>  'ЧастноеЛицо'
  }.freeze

  def login(v = nil)

    @login = v unless v.blank?
    @login

  end # login

  def password(v = nil)

    @pass = v unless v.blank?
    @pass

  end # password

  alias :pass :password

  def run_async(file_path, key: nil)

    ::SidekiqManager.create(
      tag: ::VoshodAvtoExchange::TAG,
      key: key || 0
    ) do
      ::ExchangeWorker.perform_async(file_path)
    end

    self

  end # run_async

  def exist_job?(key: nil)

    ::SidekiqManager.exist?(
      tag: ::VoshodAvtoExchange::TAG,
      key: key || 0
    )

  end # exist_job?

  def run_async_all(key: nil)

    files = ::Dir.glob( ::File.join(import_dir, '**', '{*.xml,*.zip}') )

    # Сортируем по дате последнего доступа по-возрастанию
    files.sort { |a, b|
      ::File.new(a).atime <=> ::File.new(b).atime
    }.each do |file_path|
      ::ExchangeWorker.perform_async(file_path)
    end

    self

  end # run_async_all

  def import_dir(v = nil)

    @import_dir = v unless v.blank?
    @import_dir ||= ::File.join("/tmp", "exchange_1c")

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
    @logger.log(::Logger::INFO, msg, name) if @logger
    msg

  end # log

  def close_logger

    return unless @logger
    @logger.close
    @logger = nil

  end # close_logger

  def delete_file(val = nil)

    @delete_file = (val == true)
    @delete_file

  end

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

require 'voshod_avto_1c_exchange/util'

require 'voshod_avto_1c_exchange/template'
require 'voshod_avto_1c_exchange/export'

require 'voshod_avto_1c_exchange/line_count'
require 'voshod_avto_1c_exchange/parser'
require 'voshod_avto_1c_exchange/manager'

if defined?(::Rails)
  require 'voshod_avto_1c_exchange/engine'
  require 'voshod_avto_1c_exchange/railtie'
end
