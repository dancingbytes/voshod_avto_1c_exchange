#
# Обработка цен пользователей
#
module VoshodAvtoExchange

  module Parsers

    class UserPrice < Base

      RULE_TYPES = {
        'Общее'                 => 0,
        'НоменклатурнаяГруппа'  => 1,
        'ЦеноваяГруппа'         => 2
      }.freeze

      D_ERROR = %Q(Дубль правил цен.
        Пользователь:   %{id}
        Вид правила:    %{rule_type}
        Ид правила:     %{rule_id}
        Ид типа цены:   %{price_id}
        Процент cкидки: %{persent_discount}
      ).freeze

      S_ERROR = %Q(Ошибка сохранения правил цен в базе.
        %{msg}
      ).freeze

      def start_element(name, attrs = [])

        super

        case name

          when  "Контрагент".freeze  then
            start_user

          when "Правило".freeze      then
            start_rule

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "Контрагент".freeze           then
            stop_user

          when "Правило".freeze              then
            stop_rule

          when "ПроцентСкидкиНаценки".freeze then
            parse_persent_discount

          when "Ид".freeze                   then
            parse_user_params(:user_id)
            parse_type_price
            parse_rule_id

          when "ВидПравила".freeze           then
            parse_rule_type

          when "Наименование".freeze         then
            parse_rule_good_name
            parse_price_type_name

        end # case

      end # end_element

      private

      def start_user

        @user_params = {
          rules: []
        }

      end # start_user

      def stop_user

        # Удаляем все правила пользователя
        ::Price.for_user(@user_params[:user_id]).delete_all

        # Создаем правила заново
        @user_params[:rules].each do |rule|

          pr = ::Price.find_or_initialize_by(
            user_id:        @user_params[:user_id],
            price_type:     (RULE_TYPES[rule[:rule_type]] || 0),
            price_rule_id:  rule[:rule_id] || ""
          )

          # Если запись не новая, значит дубль
          log(D_ERROR % {

            id:               @user_params[:user_id],
            rule_type:        rule[:rule_type],
            rule_id:          rule[:rule_id],
            price_id:         rule[:price_id],
            persent_discount: rule[:persent_discount]

          }) unless pr.new_record?

          pr.price_id   =  rule[:price_id]
          pr.value      =  rule[:persent_discount].try(:to_i) || 0
          pr.nom_name   = rule[:rule_good_name]
          pr.price_name = rule[:price_type_name]

          log(S_ERROR % {
            msg: pr.errors.full_messages
          }) unless pr.save

        end # each

      end # stop_user

      def start_rule

        @start_rule   = true
        @rule_params  = {}

      end # start_rule

      def stop_rule

        @start_rule = false
        @user_params[:rules] << @rule_params

      end # stop_rule

      def parse_persent_discount
        @rule_params[:persent_discount] = tag_value if rule?
      end # parse_persent_discount

      def parse_type_price
        @rule_params[:price_id]   = tag_value if rule? && type_price?
      end # parse_type_price

      def parse_rule_type
        @rule_params[:rule_type]  = tag_value if rule? && nom_price_group?
      end # parse_rule_type

      def parse_rule_id
        @rule_params[:rule_id]    = tag_value if rule? && nom_price_group?
      end # parse_rule_id

      def parse_rule_good_name
        @rule_params[:rule_good_name]  = tag_value if rule? && nom_price_group?
      end # parse_rule_good_name

      def parse_price_type_name
        @rule_params[:price_type_name]  = tag_value if rule? && type_price?
      end # parse_price_type_name

      def parse_user_params(name)
        @user_params[name] = tag_value if user?
      end # parse_user_params

      def user?
        tag == "Контрагент".freeze
      end # user?

      def nom_price_group?
        tag == "НоменклатурнаяЦеноваяГруппа".freeze
      end # nom_price_group?

      def type_price?
        tag == "ТипЦен".freeze
      end # type_price?

      def rule?
        @start_rule == true
      end # rule?

    end # UserPrice

  end # Parsers

end # VoshodAvtoExchange
