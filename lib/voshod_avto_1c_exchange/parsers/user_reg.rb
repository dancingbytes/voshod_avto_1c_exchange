module VoshodAvtoExchange

  module Parser

    class UserReg

      def initialize

        @str    = ""
        @level  = 0
        @tags   = {}
        @attrs  = {}

      end # initialize

      def start_element(name, attrs = [])

        @str          = ""
        @level        += 1
        @tags[@level] = name
        @attrs        = ::Hash[attrs]

        case name

          when "РегистрацияКлиентов" then start_parse_params

        end # case

      end # start_element

      def end_element(name)

        @level -= 1

        case name

          when "РегистрацияКлиентов"  then save_user_status
          when "Ид"                   then parse_params(:id)
          when "Наименование"         then parse_params(:name)
          when "Статус"               then parse_params(:state)

        end # case

      end # end_element

      def characters(str)
        @str << str unless str.blank?
      end # characters

      def error(string)
        ::VoshodAvtoExchange.log "[XML Errors] #{string}"
      end # error

      def warning(string)
        ::VoshodAvtoExchange.log "[XML Warnings] #{string}"
      end # warning

      def end_document
      end # end_document

      private

      def save_user_status

        @start_parse_params = false

        if @parse_params.empty?
          ::VoshodAvtoExchange.log "[РегистрацияКлиентов] Ошибка парсинга. #{tag_debug}"
          return
        end

        usr = ::User.where(id: @parse_params[:id]).first
        return unless usr

        # Одобрили регистрацию
        if @parse_params[:state] == "Утвержден"

          usr.approved = true
          usr.save(validate: false)

        # Отклонили в регистрации
        elsif @parse_params[:state] == "Отклонен"

          usr.approved = false
          usr.save(validate: false)

        end

      end # save_user_status

      def start_parse_params

        @start_parse_params = true
        @parse_params       = {}

      end # start_parse_params

      def parse_params(name)
        @parse_params[name] = @str if @start_parse_params
      end # parse_params

      def tag_debug
        "<#{@tags[@level]} #{@attrs.inpect} />"
      end # tag_debug

    end # UserReg

  end # Parser

end # VoshodAvtoExchange
