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
        answer(text: "success\nexchange_1c\n#{session_id}")

      when 'init'
        answer(text: "zip=no\nfile_limit=0")

      when 'success'

        case type

          # GET /exchange?type=catalog&mode=success
          when 'catalog'
            answer(text: "failure\nType `#{type}` is not implement")

          # GET /exchange?type=sale&mode=success
          # Пользователи
          # Заказы
          when 'sale'

            ::VoshodAvtoExchange::Exports.users_and_orders_verify(operation_id)
            answer(text: "success")

          else
            answer(text: "failure\nType `#{type}` is not found")

        end # case

      when 'query'

        case type

          # GET /exchange?type=catalog&mode=query
          when 'catalog'
            answer(text: "failure\nType `#{type}` is not implement")

          # GET /exchange?type=sale&mode=query
          # Пользователи
          # Заказы
          when 'sale'
            answer(xml: ::VoshodAvtoExchange::Exports.users_and_orders(operation_id))

          else
            answer(text: "failure\nType `#{type}` is not found")

        end # case

      else
        answer(text: "failure\nMode `#{mode}` is not found")

    end # case

    render(answer) and return

  end # get

  # POST /exchange
  def post

    ::Rails.logger.error("session_id: #{session_id}, operation_id: #{operation_id}")

    ::Rails.logger.tagged("POST /exchange [params]") {
      ::Rails.logger.error(params.inspect)
    }

    case mode

      when 'checkauth'
        answer(text: "success\nexchange_1c\n#{session_id}")

      when 'init'
        answer(text: "zip=no\nfile_limit=0")

      when 'success'
        answer(text: "success")

      when 'file'

        case type

          # POST /exchange?type=catalog&mode=file&filename=sdsd.xml
          when 'catalog'

            # Получение файла из 1С
            res = !save_file.nil?
            answer(text: res ? "success" : "failure\nFile is not found")

          # POST /exchange?type=sale&mode=file&filename=sdsd.xml
          when 'sale'

            # Получение файла из 1С
            res = !save_file.nil?
            answer(text: res ? "success" : "failure\nFile is not found")

          else
            answer(text: "failure\nType `#{type}` is not found")

        end # case

      else
        answer(text: "failure\nMode `#{mode}` is not found")

    end

    render(answer) and return

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

  def answer(text: nil, xml: nil)

    @answer = { text: text } if text
    @answer = { xml:  xml, encoding: 'utf-8' } if xml
    @answer || { text: 'failure\nОбработка данных параметров не задана' }

  end # answer

end # ExchangeController
