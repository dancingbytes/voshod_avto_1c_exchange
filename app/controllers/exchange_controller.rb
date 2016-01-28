# encoding: utf-8
class ExchangeController < ::ApplicationController

  unloadable

  before_filter       :auth
  skip_before_filter  :verify_authenticity_token

  layout false

  # GET /exchange
  def get

    ::Rails.logger.error(" --> session_id: #{session_id}, operation_id: #{operation_id}")

    ::Rails.logger.tagged("GET /exchange [params]") {
      ::Rails.logger.error(params.inspect)
    }

    case mode

      when 'checkauth'
        render(text: "success\nexchange_1c\n#{session_id}") and return

      when 'init'
        render(text: "zip=no\nfile_limit=0") and return

      when 'success'

        case type

          when 'sale'

            res = ::VoshodAvtoExchange::Exports::User.export_verify(operation_id)
            render(text: res ? "success" : "failure\nНе параметр nexchange_1c или нет данных") and return

          else
            render(text: "failure\nType `#{type}` is not found") and return

        end # case

      when 'query'

        case type

          when 'catalog'
            render(xml: ::VoshodAvtoExchange::Exports::Order.export, encoding: 'utf-8') and return

          # GET /exchange?type=sale&mode=query
          when 'sale'
            render(xml: ::VoshodAvtoExchange::Exports::User.export(operation_id), encoding: 'utf-8') and return

          else
            render(text: "failure\nType `#{type}` is not found") and return

        end # case

      else
        render(text: "failure\nMode `#{mode}` is not found") and return

    end # case

  end # get

  # POST /exchange
  def post

    ::Rails.logger.error("session_id: #{session_id}, operation_id: #{operation_id}")

    ::Rails.logger.tagged("POST /exchange [params]") {
      ::Rails.logger.error(params.inspect)
    }

    case mode

      when 'checkauth'
        render(text: "success\nexchange_1c\n#{session_id}") and return

      when 'init'
        render(text: "zip=no\nfile_limit=0") and return

      when 'success'
        render(text: "success") and return

      when 'file'

        case type

          # POST /exchange?type=sale&mode=file&filename=sdsd.xml
          when 'sale'

            # Получение файла из 1С
            res = !save_file.nil?
            render(text: res ? "success" : "failure\nFile is not found") and return

          else
            render(text: "failure\nType `#{type}` is not found") and return

        end # case

      else
        render(text: "failure\nMode `#{mode}` is not found") and return

    end

  end # post

  private

  def auth

    return true if ::VoshodAvtoExchange::login.nil?

    authenticate_or_request_with_http_basic do |login, password|
      (login == ::VoshodAvtoExchange::login && password == ::VoshodAvtoExchange::password)
    end

  end # auth

  def save_file

    return if request.body.nil? || request.body.blank?

    file_path  = ::File.join(
      ::VoshodAvtoExchange.import_dir,
      params[:filename] || "#{rand}-#{::Time.now.to_i}.xml"
    )

    ::File.open(file_path, 'wb') do |f|
      f.write request.body.read
    end

    ::Rails.logger.error("/exchange/post [save_file: #{file_path}]")
    file_path

  end # save_file

  def session_id
    @session_id ||= ::SecureRandom.hex(20)
  end # session_id

  def operation_id
    cookies[:exchange_1c] || 0
  end # operation_id

  def mode
    @mode ||= (params[:mode] || 'undefined')
  end # mode

  def type
    @type ||= (params[:type] || 'undefined')
  end # type

end # ExchangeController
