module VoshodAvtoExchange

  module User

    extend self

    XML_BASE = %q(<?xml version="1.0" encoding="utf-8"?>
      <КоммерческаяИнформация ВерсияСхемы="2.05" ДатаФормирования="%{date}T%{time}" ФорматДаты="ДФ=yyyy-MM-dd; ДЛФ=DT" ФорматВремени="ДФ=ЧЧ:мм:сс; ДЛФ=T" РазделительДатаВремя="T" ФорматСуммы="ЧЦ=18; ЧДЦ=2; ЧРД=." ФорматКоличества="ЧЦ=18; ЧДЦ=2; ЧРД=.">
      %{body}
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
          <ИНН>%{inn}</ИНН>
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

    def export

      str         = ""
      first_name  = ""
      last_name   = ""
      date        = Time.now.strftime('%Y-%m-%d')
      time        = Time.now.strftime('%H:%M:%S')

      ::User.where(approved: false).each { |user|

        last_name, first_name, _ = user.contact_person.split(/\s/)

        str << ::VoshodAvtoExchange::User::XML_USER % {

          kid:            user.id.to_s,
          inn:            user.inn,
          date:           date,
          time:           time,
          company:        user.company,
          first_name:     first_name,
          last_name:      last_name,
          address:        user.address,
          postcode:       "",
          city:           "",
          street:         "",
          email:          user.email,
          phone:          user.phone,
          contact_person: user.contact_person

        }

      }

      ::VoshodAvtoExchange::User::XML_BASE % {
        date: date,
        time: time,
        body: str
      }

    end # export

  end # User

end # VoshodAvtoExchange
