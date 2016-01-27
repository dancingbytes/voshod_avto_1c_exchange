# encoding: utf-8
class ExchangeController < ::ApplicationController

  unloadable

  before_filter       :auth
  skip_before_filter  :verify_authenticity_token

  layout false

  # GET /exchange
  def get

    ::Rails.logger.tagged("GET /exchange [params]") {
      ::Rails.logger.error(params.inspect)
    }

    ::Rails.logger.tagged("GET /exchange [cookie]") {
      ::Rails.logger.error(cookie.inspect)
    }

    case params[:mode]

      when 'checkauth'

        render(text: "success\nexchange_1c\n#{rand(9999)}") and return

      when 'init'

        render(text: "zip=no\nfile_limit=99999999999999999") and return

      when 'success'

        case params[:type]

          when 'sale'

            render(text: "Ok") and return

          else

            render(text: "success") and return

        end # case

      when 'query'

        case params[:type]

          when 'catalog'

            render(xml: ::VoshodAvtoExchange::Order.export, encoding: 'utf-8') and return

          # GET exchange?type=sale&mode=query
          when 'sale'

            render(xml: ::VoshodAvtoExchange::User.export, encoding: 'utf-8') and return

        else

          render(text: "Type `#{params[:type]}` is not found") and return

        end

      else

        render(text: "Mode `#{params[:mode]}` is not found") and return

    end

  end # get

  # POST /exchange
  def post

    ::Rails.logger.tagged("POST /exchange [params]") {
      ::Rails.logger.error(params.inspect)
    }

    ::Rails.logger.tagged("POST /exchange [cookie]") {
      ::Rails.logger.error(cookie.inspect)
    }

    save_file

    case params[:mode]

      when 'checkauth'

        render(text: "success\nexchange_1c\n#{rand(9999)}") and return

      when 'init'

        render(text: "zip=no\nfile_limit=99999999999999999") and return

      when 'success'

        render(text: "success") and return

      when 'query'

        case params[:type]

          when 'catalog'

            render(xml: ::VoshodAvtoExchange::Order.export, encoding: 'utf-8') and return

          when 'sale'

            render(text: "Type `#{params[:type]}` is not found") and return

        else

          render(text: "Type `#{params[:type]}` is not found") and return

        end

      else

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
