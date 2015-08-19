require 'nokogiri'

module VoshodAvtoExchange

  extend self

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
    "#{uid[0,8]}-#{uid[7,4]}-#{uid[12,4]}-#{uid[16,4]}-#{uid[20,12]}"

  end # to_1c_id

  XML_BASE = %q(<?xml version="1.0" encoding="utf-8"?>
    <КоммерческаяИнформация ВерсияСхемы="2.05" ДатаФормирования="%{date}T%{time}" ФорматДаты="ДФ=yyyy-MM-dd; ДЛФ=DT" ФорматВремени="ДФ=ЧЧ:мм:сс; ДЛФ=T" РазделительДатаВремя="T" ФорматСуммы="ЧЦ=18; ЧДЦ=2; ЧРД=." ФорматКоличества="ЧЦ=18; ЧДЦ=2; ЧРД=.">
    <Документы>
    %{body}
    </Документы>
    </КоммерческаяИнформация>).freeze

  XML_USER = %q(<Документ>
    <Ид>%{kid}</Ид>
    <Номер>#klient</Номер>
    <Дата>%{date}</Дата>
    <ХозОперация>Прочие</ХозОперация>
    <Роль>Продавец</Роль>
    <Валюта>руб</Валюта>
    <Курс>1</Курс>
    <Сумма>0.0</Сумма>

    <Контрагенты>
      <Контрагент>
        <Ид>%{kid}</Ид>
        <Наименование>%{company}</Наименование>
        <ПолноеНаименование>%{company}</ПолноеНаименование>
        <Фамилия>%{last_name}</Фамилия>
        <Имя>%{first_name}</Имя>
        <АдресРегистрации>
          <Представление>%{address}</Представление>
          <АдресноеПоле>
            <Тип>Почтовый индекс</Тип>
            <Значение>%{postcode}</Значение>
          </АдресноеПоле>
          <АдресноеПоле>
            <Тип>Страна</Тип>
            <Значение>Россия</Значение>
          </АдресноеПоле>
          <АдресноеПоле>
            <Тип>Город</Тип>
            <Значение>%{city}</Значение>
          </АдресноеПоле>
          <АдресноеПоле>
            <Тип>Улица</Тип>
            <Значение>%{street}</Значение>
          </АдресноеПоле>
        </АдресРегистрации>

        <Контакты>
          <Контакт>
            <Тип>Почта</Тип>
            <Значение>%{email}</Значение>
          </Контакт>
          <Контакт>
            <Тип>Телефон рабочий</Тип>
            <Значение>%{phone}</Значение>
          </Контакт>
        </Контакты>

        <Представители>
          <Представитель>
            <Контрагент>
              <Отношение>Контактное лицо</Отношение>
              <Ид>%{kid}</Ид>
              <Наименование>%{contact_person}</Наименование>
            </Контрагент>
          </Представитель>
        </Представители>

        <Роль>Покупатель</Роль>
      </Контрагент>
    </Контрагенты>

    <Время>%{time}</Время>
    <Комментарий></Комментарий>

    <Товары>
    </Товары>

  </Документ>).freeze

end # VoshodAvtoExchange

require 'voshod_avto_1c_exchange/version'

if defined?(::Rails)
  require 'voshod_avto_1c_exchange/engine'
  require 'voshod_avto_1c_exchange/railtie'
end
