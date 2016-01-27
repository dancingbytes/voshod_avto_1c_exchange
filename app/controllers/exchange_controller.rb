# encoding: utf-8
class ExchangeController < ::ApplicationController

  unloadable

  before_filter       :auth
  skip_before_filter  :verify_authenticity_token

  layout false

  # GET /exchange
  def get

    ::Rails.logger.tagged("/exchange/get") {
      ::Rails.logger.error(params.inspect)
    }

    case params[:mode]

      when 'checkauth'

        ::Rails.logger.error("/exchange/get [checkauth]")

        render(text: "success\nexchange_1c\n#{rand(9999)}") and return

      when 'init'

        ::Rails.logger.error("/exchange/get [init]")

        render(text: "zip=no\nfile_limit=99999999999999999") and return

      when 'success'

        ::Rails.logger.error("/exchange/get [success]")

        render(text: "success") and return

      when 'query'

        case params[:type]

          when 'catalog'

            ::Rails.logger.error("/exchange/get [query: catalog]")

            render(xml: ::VoshodAvtoExchange::Order.export, encoding: 'utf-8') and return

          when 'sale'

            ::Rails.logger.error("/exchange/get [query: sale]")

            render(xml: ::VoshodAvtoExchange::User.export, encoding: 'utf-8') and return

        else

          ::Rails.logger.error("/exchange/get [query: *]")

          render(text: "Type `#{params[:type]}` is not found") and return

        end

      else

        ::Rails.logger.error("/exchange/get [get: *]")

        render(text: "Mode `#{params[:mode]}` is not found") and return

    end

  end # get

  # POST /exchange
  def post

    ::Rails.logger.tagged("/exchange/post") {
      ::Rails.logger.error(params.inspect)
    }

    save_file

    case params[:mode]

      when 'checkauth'

        ::Rails.logger.error("/exchange/post [checkauth]")

        render(text: "success\nexchange_1c\n#{rand(9999)}") and return

      when 'init'

        ::Rails.logger.error("/exchange/post [init]")

        render(text: "zip=no\nfile_limit=99999999999999999") and return

      when 'success'

        ::Rails.logger.error("/exchange/post [success]")

        render(text: "success") and return

      when 'query'

        case params[:type]

          when 'catalog'

            ::Rails.logger.error("/exchange/post [query: catalog]")

            render(xml: ::VoshodAvtoExchange::Order.export, encoding: 'utf-8') and return

          when 'sale'

            ::Rails.logger.error("/exchange/post [query: sale]")

            render(text: "Type `#{params[:type]}` is not found") and return

        else

          ::Rails.logger.error("/exchange/post [query: *]")

          render(text: "Type `#{params[:type]}` is not found") and return

        end

      else

        ::Rails.logger.error("/exchange/post [mode: *]")

        render(text: "Mode `#{params[:mode]}` is not found") and return

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

    file_name = ::File.join(::Rails.root, 'tmp', "#{rand}-#{::Time.now.to_f}.xml")
    ::File.open(file_path, 'wb') do |f|
      f.write request.body.read
    end
    ::Rails.logger.error("/exchange/post [save_file: #{file_name}]")


  end # save_file

end # ExchangeController
