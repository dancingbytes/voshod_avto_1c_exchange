# encoding: utf-8
class ExchangeController < ::ApplicationController

  unloadable

  before_action       :auth
  skip_before_action  :verify_authenticity_token

  layout false

  # GET /exchange
  def get
    ::Rails.logger.tagged("[GET] /exchange [params]") {
      ::Rails.logger.info("session_id: #{session_id}, operation_id: #{operation_id}")
      ::Rails.logger.info(params.inspect)
    }

    case mode
    when 'checkauth'  then
      answer(text: "success\nexchange_1c\n#{session_id}")
    when 'init'       then
      answer(text: "zip=yes\nfile_limit=0")
    when 'success'    then
      case type
      
      # GET /exchange?type=catalog&mode=success
      when 'catalog'  then
        answer(text: "failure\nType `#{type}` is not implement")
      
      # GET /exchange?type=sale&mode=success
      # Пользователи
      # Заказы
      when 'sale'     then
        ::VoshodAvtoExchange::Exports.users_and_orders_verify(operation_id)
        answer(text: "success")
      else
        answer(text: "failure\nType `#{type}` is not found")
      end # case
    when 'query' then
      case type
      
        # GET /exchange?type=catalog&mode=query
      when 'catalog' then
        answer(text: "failure\nType `#{type}` is not implement")
      
      # GET /exchange?type=sale&mode=query
      # Пользователи
      # Заказы
      when 'sale' then
        answer(xml: ::VoshodAvtoExchange::Exports.users_and_orders(operation_id))

        # debug запись файла обмена заказами
        # File.open("public/1c.xml", "w"){ |f| f << @answer[:xml]}

      # GET /exchange?type=users_list&mode=query&id=123
      # Список пользователей по заданному списку id
      when 'users_list'    then
        answer(xml: ::VoshodAvtoExchange::Exports::User.list(
          users_ids: params[:id].to_s.split(',')
        ))
      
      # GET /exchange?type=orders_list&mode=query&id=123
      # Спсисок заказов по заданному списку id
      when 'orders_list'   then
        answer(xml: ::VoshodAvtoExchange::Exports::Order.list(
          orders_ids: params[:id].to_s.split(',')
        ))
      else
        answer(text: "failure\nType `#{type}` is not found")
      end # case
    
    # Узнаем, пришел ли файл выгрузки
    when 'import' then
      if ::VoshodAvtoExchange.exist_job?(key: operation_id)
        answer(text: "success")
      else
        answer(text: "failure\nFile `#{params[:filename]}` is not found")
      end
    
    # На все остальное отвечаем ошибкой
    else
      answer(text: "failure\nMode `#{mode}` is not found")
    end # case

    render(answer)
  end # get

  # POST /exchange
  def post
    ::Rails.logger.tagged("[POST] /exchange [params]") {
      ::Rails.logger.info("session_id: #{session_id}, operation_id: #{operation_id}")
      ::Rails.logger.info(params.inspect)
    }

    case mode
    when 'checkauth'  then
      answer(text: "success\nexchange_1c\n#{session_id}")
    when 'init'       then
      answer(text: "zip=no\nfile_limit=0")
    when 'success'    then
      answer(text: "success")
    when 'file'
      case type
      # POST /exchange?type=catalog&mode=file&filename=sdsd.xml
      when 'catalog'  then
        # Получение файла из 1С
        res = !save_file.nil?
        answer(text: res ? "success" : "failure\nFile is not found")
      # POST /exchange?type=sale&mode=file&filename=sdsd.xml
      when 'sale'     then
        # Получение файла из 1С
        res = !save_file.nil?
        answer(text: res ? "success" : "failure\nFile is not found")
      else
        answer(text: "failure\nType `#{type}` is not found")
      end
    # На все остальное отвечаем ошибкой
    else
      answer(text: "failure\nMode `#{mode}` is not found")
    end

    render(answer)
  end

  private

  def auth

    ::Rails.logger.tagged("[GET] /exchange [auth|start]") {
      ::Rails.logger.info(params.inspect)
    }

    authenticate_or_request_with_http_basic do |login, password|

      ::Rails.logger.tagged("[GET] /exchange [auth]") {
        ::Rails.logger.info("login: #{login}, password: #{password}")
      }

      (login == ::VoshodAvtoExchange::login && password == ::VoshodAvtoExchange::password)

    end

  end # auth

  def save_file

    return if request.raw_post.nil? || request.raw_post.blank?

    file_path = ::File.join(
      ::VoshodAvtoExchange.import_dir,
      "#{operation_id}-#{params[:filename]}"
    )

    ::File.open(file_path, 'wb') do |f|
      f.write read_file
    end

    ::Rails.logger.info("/exchange/post [save_file: #{file_path}]")

    # Создаем задачу по обработку файла
    ::VoshodAvtoExchange.run_async(file_path, key: operation_id)

    file_path

  end # save_file

  def session_id
    @session_id ||= ::SecureRandom.hex(20)
  end

  def operation_id
    cookies[:exchange_1c] || params[:exchange_1c] || 0
  end

  def mode
    @mode ||= (params[:mode] || 'undefined')
  end

  def type
    @type ||= (params[:type] || 'undefined')
  end

  def answer(text: nil, xml: nil)

    @answer = { plain: text } if text
    @answer = { xml: xml, encoding: 'utf-8' } if xml
    @answer || { plain: 'failure\nОбработка параметров не задана' }

  end # answer

  def read_file

    return request.raw_post if params[:data].nil?

    if params[:data].is_a?(::ActionDispatch::Http::UploadedFile)
      ::Base64.decode64(params[:data].read)
    else
      ::Base64.decode64(params[:data])
    end

  end # read_file

end # ExchangeController
