#
# Обработка цен пользователей
#
module VoshodAvtoExchange

  module Parsers

    class UserPrice < Base

      RULE_TYPES = {
        'Общее'                 => 0,
        'НоменклатурнаяГруппа'  => 1,
        'ЦеноваяГруппа'         => 2,
        'Номенклатура'          => 3
      }.freeze

      INSERT_OR_UPDATE_SQL = %{
        INSERT INTO prices (
          user_id,
          price_type,
          price_rule_id,
          price_id,
          value,
          fix_value,
          nom_name,
          price_name
        )
        VALUES (
          %{user_id},
          %{price_type},
          %{price_rule_id},
          %{price_id},
          %{value},
          %{fix_value},
          %{nom_name},
          %{price_name}
        )
        ON CONFLICT (user_id, price_type, price_rule_id) DO UPDATE SET
          price_id   = %{price_id},
          value      = %{value},
          fix_value  = %{fix_value},
          nom_name   = %{nom_name},
          price_name = %{price_name};
      }.freeze

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

          when "Цена".freeze                 then
            parse_fix_price

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

        # Ищем пользователя
        user = ::User.where(uid: @user_params[:user_id]).take

        unless user

          log(S_ERROR % {
            msg: "Пользователь #{@user_params[:user_id]} не найден"
          }) and return

        end

        # Удаляем все правила пользователя
        ::Price.where(user_id: user.id).delete_all

        # Создаем правила заново
        @user_params[:rules].each do |rule|

          insert_or_update(

            user_id:          user.id,
            price_type:       RULE_TYPES[rule[:rule_type]],
            price_rule_id:    rule[:rule_id],
            price_id:         rule[:price_id],
            value:            rule[:persent_discount],
            fix_value:        rule[:fix_price] || 0,
            nom_name:         rule[:rule_good_name],
            price_name:       rule[:price_type_name].to_s.presence || 'Неизвестная цена'

          )

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

      def parse_fix_price
        @rule_params[:fix_price] = tag_value if rule?
      end # parse_fix_price

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

      def insert_or_update(
        user_id:,
        price_type:,
        price_rule_id:,
        price_id:,
        value:        0,
        fix_value:    0,
        nom_name:     '',
        price_name:   ''
      )

        sql(INSERT_OR_UPDATE_SQL % {

          user_id:        user_id,
          price_type:     price_type || 0,
          price_rule_id:  quote(price_rule_id || ''),
          price_id:       quote(price_id || ''),
          value:          value.try(:to_f) || 0,
          fix_value:      fix_value.try(:to_f) || 0,
          nom_name:       quote(nom_name || ''),
          price_name:     quote(price_name || '')

        })
        self

      end

      def sql(str)
        ::ApplicationRecord.execute(str)
      end

      def quote(el)
        ::ApplicationRecord.quote(el)
      end

    end # UserPrice

  end # Parsers

end # VoshodAvtoExchange
