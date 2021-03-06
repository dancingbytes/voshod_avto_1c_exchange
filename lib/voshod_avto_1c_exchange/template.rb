# encoding: utf-8
module VoshodAvtoExchange

  module Template

    XML_BASE = %Q(<?xml version="1.0" encoding="utf-8"?>
      <КоммерческаяИнформация ВерсияСхемы="2.05" ДатаФормирования="%{date}T%{time}" ФорматДаты="ДФ=yyyy-MM-dd; ДЛФ=DT" ФорматВремени="ДФ=ЧЧ:мм:сс; ДЛФ=T" РазделительДатаВремя="T" ФорматСуммы="ЧЦ=18; ЧДЦ=2; ЧРД=." ФорматКоличества="ЧЦ=18; ЧДЦ=2; ЧРД=.">
      %{body}
      </КоммерческаяИнформация>).freeze

    USER = %Q(<Документ>
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
          <ВидКонтрагента>%{user_type}</ВидКонтрагента>
          <Наименование>%{company}</Наименование>
          <ПолноеНаименование>%{company}</ПолноеНаименование>
          <Фамилия>%{last_name}</Фамилия>
          <Имя>%{first_name}</Имя>
          <АдресРегистрации>
            <Представление></Представление>
            <АдресноеПоле>
              <Тип>Почтовый индекс</Тип>
              <Значение></Значение>
            </АдресноеПоле>
            <АдресноеПоле>
              <Тип>Страна</Тип>
              <Значение>Россия</Значение>
            </АдресноеПоле>
            <АдресноеПоле>
              <Тип>Город</Тип>
              <Значение></Значение>
            </АдресноеПоле>
            <АдресноеПоле>
              <Тип>Улица</Тип>
              <Значение></Значение>
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

    ORDER_ITEM = %Q(<Товар>
      <Ид>%{item_id}</Ид>
      <Артикул>%{item_mog}</Артикул>
      <АртикулПроизводителя>%{oem_num}</АртикулПроизводителя>
      <Производитель>%{oem_brand}</Производитель>
      <КодПоставщика>%{p_code}</КодПоставщика>
      <Наименование>%{item_name}</Наименование>
      <КодСтранаПроисхождения>%{item_contry_code}</КодСтранаПроисхождения>
      <СтранаПроисхождения>%{item_contry_name}</СтранаПроисхождения>
      <НомерГТД>%{item_gtd}</НомерГТД>
      <БазоваяЕдиница Код="796" НаименованиеПолное="Штука" МеждународноеСокращение="PCE">шт</БазоваяЕдиница>
      <СтавкиНалогов>
        <СтавкаНалога>
          <Наименование>НДС</Наименование>
          <Ставка>18</Ставка>
        </СтавкаНалога>
      </СтавкиНалогов>
      <ЗначенияРеквизитов>
        <ЗначениеРеквизита>
          <Наименование>ВидНоменклатуры</Наименование>
          <Значение>Оптовый товар</Значение>
        </ЗначениеРеквизита>
        <ЗначениеРеквизита>
          <Наименование>ТипНоменклатуры</Наименование>
          <Значение>Товар</Значение>
        </ЗначениеРеквизита>
      </ЗначенияРеквизитов>
      <ЦенаЗакупа>%{purchase_price}</ЦенаЗакупа>
      <ЦенаЗаЕдиницу>%{item_price}</ЦенаЗаЕдиницу>
      <Количество>%{item_count}</Количество>
      <Сумма>%{item_total}</Сумма>
      <Единица>шт</Единица>
      <Коэффициент>1</Коэффициент>
      <Налоги>
        <Налог>
          <Наименование>НДС</Наименование>
          <УчтеноВСумме>true</УчтеноВСумме>
          <Сумма>0</Сумма>
          <Ставка>Без налога</Ставка>
        </Налог>
      </Налоги>
    </Товар>).freeze

    ORDER = %Q(<Документ>
      <Ид>%{kid}</Ид>
      <Дата>%{date}</Дата>
      <Время>%{time}</Время>
      <ХозОперация>Заказ товара</ХозОперация>
      <Роль>Продавец</Роль>
      <Валюта>руб</Валюта>
      <Курс>1</Курс>
      <Сумма>%{price}</Сумма>
      <Комментарий>%{comment}</Комментарий>

      <ВидДоставки>%{delivery_type}</ВидДоставки>
      <АдресДоставки>%{delivery_address}</АдресДоставки>

      <Контрагенты>
        <Контрагент>
          <Ид>%{uid}</Ид>
          <ВидКонтрагента>%{user_type}</ВидКонтрагента>
          <Наименование>%{company}</Наименование>
          <ОфициальноеНаименование>%{full_company}</ОфициальноеНаименование>
          <Роль>Покупатель</Роль>
        </Контрагент>
      </Контрагенты>
      <СрокПлатежа>%{payment_date}</СрокПлатежа>
      <Налоги>
        <Налог>
          <Наименование>НДС</Наименование>
          <УчтеноВСумме>true</УчтеноВСумме>
          <Сумма>0</Сумма>
        </Налог>
      </Налоги>
      <Товары>
        %{items}
      </Товары>
      <ЗначенияРеквизитов>
        <ЗначениеРеквизита>
          <Наименование>Номер по 1С</Наименование>
          <Значение>%{number_1c}</Значение>
        </ЗначениеРеквизита>
        <ЗначениеРеквизита>
          <Наименование>Дата по 1С</Наименование>
          <Значение>%{data_1c}</Значение>
        </ЗначениеРеквизита>
        <ЗначениеРеквизита>
          <Наименование>ПометкаУдаления</Наименование>
          <Значение>%{detete_1c}</Значение>
        </ЗначениеРеквизита>
        <ЗначениеРеквизита>
          <Наименование>Проведен</Наименование>
          <Значение>%{hold_on_1c}</Значение>
        </ЗначениеРеквизита>
      </ЗначенияРеквизитов>
    </Документ>).freeze

  end # Template

end # VoshodAvtoExchange
