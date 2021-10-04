# frozen_string_literal: true
# encoding: utf-8
#
# Обработка import-файла из 1С Челябинска
#
module VoshodAvtoExchange
  module Parsers
    class ChelImport < Base

      ITEMS_SET_RAW_ALL           = %{UPDATE items SET raw = 't' WHERE p_code = '%{p_code}'}
      ITEMS_DELETE_RAW_ALL        = %{DELETE FROM items WHERE raw = 't' AND p_code = '%{p_code}'}
      CATALOGS_SET_RAW_FALSE_ALL  = %{UPDATE catalogs SET raw = 'f'}
      CATALOGS_RESET_TREE         = %{UPDATE catalogs SET lft = null, rgt = null}
      CATALOGS_DELETE_RAW_ALL     = %{DELETE FROM catalogs WHERE raw = 't'}
      CATALOGS_SET_RAW_ALL        = %{UPDATE catalogs SET raw = 't'}

      CATALOG_INSERT_OR_UPDATE    = <<~SQL
        INSERT INTO catalogs (
          raw,
          url,
          parent_id,
          va_parent_id,
          va_catalog_id,
          name
        ) VALUES (
          %{raw},
          %{url},
          %{parent_id},
          %{va_parent_id},
          %{va_catalog_id},
          %{name}
        ) ON CONFLICT (va_catalog_id) DO UPDATE SET raw = %{raw},
          url = %{url},
          parent_id = %{parent_id},
          va_parent_id = %{va_parent_id},
          name = %{name}
        RETURNING id
      SQL

      ITEM_INSERT_OR_UPDATE = <<~SQL
        INSERT INTO items (
          p_code,
          mog,
          oem_num,
          oem_brand,
          shipment,
          raw,
          updated_at,
          va_catalog_id,
          va_item_id,
          va_nom_group,
          va_price_group,
          name,
          unit_code,
          department,
          search_tags,
          instituted_at
        ) VALUES (
          %{p_code},
          %{mog},
          %{oem_num},
          %{oem_brand},
          %{shipment},
          %{raw},
          %{updated_at},
          %{va_catalog_id},
          %{va_item_id},
          %{va_nom_group},
          %{va_price_group},
          %{name},
          %{unit_code},
          %{department},
          %{search_tags},
          %{instituted_at}
        ) ON CONFLICT (p_code, mog, oem_num, oem_brand) DO UPDATE SET raw = %{raw},
          shipment = %{shipment},
          updated_at = %{updated_at},
          va_catalog_id = %{va_catalog_id},
          va_item_id = %{va_item_id},
          va_nom_group = %{va_nom_group},
          va_price_group = %{va_price_group},
          name = %{name},
          unit_code = %{unit_code},
          department = %{department},
          search_tags = %{search_tags},
          instituted_at = %{instituted_at},
          published = 't'
      SQL

      S_C_ERROR = %Q(Ошибка сохранения каталога в базу.
        %{msg}
      )

      S_I_ERROR = %Q(Ошибка сохранения товара в базу.
        %{msg}
      )

      def initialize(p_code:, doc_info: {})
        super

        @p_code     = p_code
        @doc_info   = doc_info
        start_catalogs
      end # new

      def start_element(name, attrs = [])
        super

        case name
        when "Группы"
          start_subcatalogs_group
          add_catalog
        when "Группа"
          up_catalog_level
          start_catalog_group
        when "Свойство"
          start_feature_params
        when "Каталог"
          update_mode
          stop_work_with_catalogs
          start_items
          start_work_with_items
        when "Товар"
          start_item
        when "ЗначениеРеквизита"
          start_item_param
        when "ЗначенияСвойства"
          start_item_character
        end # case
      end # start_element

      def end_element(name)
        super

        case name
        when "Классификатор"
          stop_catalogs
        when "Ид"
          # Каталоги
          parse_catalog(:id)
          parse_id_items_feature

          # Товары
          parse_item(:id)           if item_only?
          parse_item(:catalog_id)   if item_catalog?
          parse_item_character(:key)
        when "Наименование"
          # Каталоги
          parse_catalog(:name)
          parse_name_items_feature

          # Товары
          parse_item(:name)       if item_only?
          parse_item_param(:key)
        when "Группа"
          down_catalog_level
          add_catalog
        when "Свойство"
          stop_feature_params
        when "Каталог"
          stop_items #
        when "Товар"
          stop_item
          save_item
        when "Отдел"
          parse_item(:department) if item_only?
        when "Штрихкод"
          parse_item(:barcode) if item_only?
        when "Артикул"
          parse_item(:mog) if item_only?
        when "АртикулПроизводителя"
          parse_item(:oem_num) if item_only?
        when "НомерГТД"
          parse_item(:gtd) if item_only?
        when "ДополнительноеОписаниеНоменклатуры"
          parse_item(:ext_param) if item_only?
        when "КодСтранаПроисхождения"
          parse_item(:contry_code) if item_only?
        when "СтранаПроисхождения"
          parse_item(:contry_name) if item_only?
        when "КратностьОтгрузки"
          parse_item(:shipment) if item_only?
        when "Производитель"
          parse_item(:oem_brand) if item_only?
        when "ПоисковыеТеги"
          parse_item(:search_tags) if item_only?
        when "ЦеноваяГруппа"
          parse_item(:price_group, attrs["ИД"]) if item_only?
        when "НоменклатурнаяГруппа"
          parse_item(:nom_group, attrs["ИД"]) if item_only?
        when "БазоваяЕдиница"
          parse_item(:unit_code, attrs["Код"]) if item_only?
          parse_item(:unit) if item_only?
        when "Значение"
          parse_item_param(:value)
          parse_item_character(:value)
        when "ЗначениеРеквизита"
          stop_item_param
        when "ЗначенияСвойства"
          stop_item_character
        end # case
      end # end_element

      private

      #
      # Обработка каталогов
      #
      def start_catalogs
        @start_catalogs   = true
        @catalog          = {}
        @catalog_level    = 0
        @catalog_parents  = []
        @catalogs_meta    = {}

        # Характеристики товаров
        @items_features   = {}

        # Способ обновления товаров и каталогов
        @full_update      = false

        start_work_with_catalogs
      end # start_parse_catalogs

      def stop_catalogs
        @start_catalogs = false
      end # stop_catalogs

      def up_catalog_level
        @catalog_level += 1
      end # up_catalog_level

      def down_catalog_level
        @catalog_level -= 1
      end # down_catalog_level

      def start_subcatalogs_group
        @catalog_parents[@catalog_level] = @catalog[:id] if @start_catalogs
      end # start_subcatalogs_group

      def start_catalog_group
        return unless @start_catalogs

        @start_catalog_group = true
        @catalog = {
          p_parent_id:  @catalog_parents[@catalog_level-1]
        }
      end # start_catalog_group

      def catalog?
        @start_catalogs && @start_catalog_group
      end # catalog?

      def general_items_feature?
        @start_catalogs && @start_feature_params
      end # general_items_feature?

      def parse_catalog(key)
        @catalog[key]   = tag_value if catalog?
      end # parse_catalog

      def add_catalog
        return if !catalog? || @catalog.nil? || @catalog.empty?

        @prev_saved_catalog_id  = @saved_catalog_id
        @saved_catalog_id       = @catalog[:id]

        return if @saved_catalog_id   == @prev_saved_catalog_id

        # Сохраняем каталог в базе
        save_catalog
      end # add_catalog

      def start_feature_params
        @start_feature_params = true
      end # start_feature_params

      def stop_feature_params
        @stop_feature_params = false
        @items_features[@items_feature_id] = @items_feature_name
      end # stop_feature_params

      def parse_id_items_feature
        @items_feature_id = tag_value   if general_items_feature?
      end # parse_id_items_feature

      def parse_name_items_feature
        @items_feature_name = tag_value if general_items_feature?
      end # parse_name_items_feature

      #
      # Способ обновления данных
      #
      def update_mode
        @full_update = ["false", false].include?(attrs["СодержитТолькоИзменения"])
      end # update_mode

      #
      # Обработка товаров
      #
      def start_items
        @start_items = true
      end # start_items

      def stop_items
        @start_items = false
        stop_work_with_items #
      end # stop_items

      def start_item
        return unless @start_items

        @start_item = true
        @item       = {
          p_code:       @p_code,
          params:       {},
          characters:   {}
        }
      end # start_item

      def stop_item
        return unless @start_items

        @start_item = false
      end # stop_item

      def for_item?
        @start_items && @start_item
      end # for_item?

      def item_only?
        for_item? && tag == "Товар"
      end # item_only?

      def item_catalog?
        for_item? && tag == "Группы"
      end # item_catalog?

      def item_character?
        for_item? && tag == "ЗначенияСвойства"
      end # item_character?

      def item_param?
        for_item? && tag == "ЗначениеРеквизита"
      end # item_param?

      def parse_item(key, val = nil)
        @item[key] = val || tag_value
      end # parse_item

      def start_item_param
        @item_param = {}
      end # start_item_param

      def stop_item_param
        return if @item_param.nil? || @item_param.empty?

        @item[:params][@item_param[:key]] = @item_param[:value]
      end # stop_item_param

      def parse_item_param(key)
        @item_param[key] = tag_value if item_param?
      end # parse_item_param

      def start_item_character
        @item_character = {}
      end # start_item_character

      def stop_item_character
        return if @item_character.nil? || @item_character.empty?

        key = @items_features[@item_character[:key]] || @item_character[:key]
        val = @item_character[:value]

        @item[:characters][key] = val
      end # stop_item_character

      def parse_item_character(key)
        @item_character[key] = tag_value if item_character?
      end # parse_item_character

      def time_stamp
        return @time_stamp unless @time_stamp.nil?

        @time_stamp = @doc_info["ДатаФормирования"].try(:to_time).try(:utc).try(:to_i) || 0
      end # time_stamp

      def save_catalog
        return if @catalog.nil? || @catalog.empty?

        begin
          str_sql = (CATALOG_INSERT_OR_UPDATE % {
            # Ссылка на каталог
            url:            quote("1-#{@catalog[:id]}"),

            # ID каталога в 1С
            va_catalog_id:  quote(@catalog[:id]),

            # Выбираем идентификатор родительского каталога
            parent_id:      quote(@catalogs_meta[@catalog[:p_parent_id]]),

            # Данные обработаны
            raw:            quote('f'),

            # Название
            name:           quote(@catalog[:name].to_s.squish[0..250]),

            # ID родительского каталога в 1С
            va_parent_id:   quote(@catalog[:p_parent_id].to_s)
          })

          req_id = sql(str_sql).first['id']

          if req_id.nil?
            # Если пусто -- пишем ошибку в лог
            log(S_C_ERROR % { msg: str_sql })
          else
            # Иначе, сохраняем ID текущего каталога
            @catalogs_meta[@catalog[:id]] = req_id
          end
        rescue => ex
          log(S_C_ERROR % {
            msg: [ex.message].push(ex.backtrace).join("\n")
          })
          Raven.capture_exception(ex)
        end
      end # save_catalog

      def save_item #
        return if @item.nil? || @item.empty?

        instituted_at = @item[:characters]['Дата создания номенклатуры'].try(:to_time).try(:utc)

        begin
          sql(ITEM_INSERT_OR_UPDATE % {
            p_code:             quote(@item[:p_code]),
            mog:                quote(@item[:mog].to_s.squish[0..99]),

            oem_num:            quote(
                                  ::CrossModule.clean(@item[:oem_num].to_s.squish[0..99])
                                ),

            oem_brand:          quote(
                                  ::VendorAliasModule.clean(@item[:oem_brand].to_s.squish[0..99])
                                ),

            raw:                quote('f'),
            updated_at:         quote(::Time.now.utc),
            shipment:           @item[:shipment].try(:to_i) || 1,
            va_catalog_id:      quote(@item[:catalog_id].to_s),
            va_item_id:         quote(@item[:id].to_s),
            va_nom_group:       quote(@item[:nom_group].to_s),
            va_price_group:     quote(@item[:price_group].to_s),
            name:               quote(@item[:name].to_s.squish[0..250]),
            unit_code:          @item[:unit_code].to_i,
            department:         quote(@item[:department].to_s.squish[0..99]),
            search_tags:        quote(@item[:search_tags].to_s.squish),
            instituted_at:      quote(instituted_at)
          })
        rescue => ex
          log(S_I_ERROR % {
            msg: [ex.message].push(ex.backtrace).join("\n")
          })
          Raven.capture_exception(ex)
        end

        reindex_for(@item[:id].to_s)
      end # save_item

      def reindex_for(item_id)
        # Ищем товар по 1C-айди
        itm = ::Item.where(va_item_id: item_id).take
        # Если нашли -- обновляем индекс
        # ::SearchModule.reindex_for(itm) if itm
        # Search v2
        ::Elasticsearch::IndexProduct.call(product: itm) if itm
      rescue => ex
        log(S_I_ERROR % {
          msg: [ex.message].push(ex.backtrace).join("\n")
        })
        Raven.capture_exception(ex)
      end

      #
      # Начало обработки каталогов
      #
      def start_work_with_catalogs
        # При полной обработке данных, помечаем все каталоги как "сырые",
        # что бы в дальнейшем понять какие каталоги нужно удалит из каталога
        sql(CATALOGS_SET_RAW_ALL)
      end # start_work_with_catalogs

      #
      # Окончание обработки каталогов
      #
      def stop_work_with_catalogs
        # Все "сырые" данные удаляем
        if @full_update
          sql(CATALOGS_DELETE_RAW_ALL)
          sql(CATALOGS_RESET_TREE)

          ::Catalog.rebuild!
        else
          sql(CATALOGS_SET_RAW_FALSE_ALL)
        end # if
      end # stop_work_with_catalogs

      #
      # Начало обработки товаров
      #
      def start_work_with_items
        if @full_update
          # При полной обработке данных, помечаем все товары как "сырые",
          # что бы в дальнейшем понять какие товары нужно удалит из каталога
          sql(ITEMS_SET_RAW_ALL % {
            p_code: @p_code
          })
        end # if
      end # start_work_with_items

      #
      # Окончание обработки товаров
      #
      def stop_work_with_items
        if @full_update
          # Удаляем все товары, которые не были обработаны
          # sql(ITEMS_DELETE_RAW_ALL % {
          #   p_code: @p_code
          # })

          # DELETE FROM items WHERE raw = 't' AND p_code = '%{p_code}

          # 2020-11-10 Заменяем удаление сбросом атрибута published
          # TODO после првоерки удалить запрос ITEMS_DELETE_RAW_ALL #
          #
          Item.where('raw=? and p_code=?', 't', @p_code).update_all(published: false)
        end # if
      end # stop_work_with_items

      def sql(str)
        ::ApplicationRecord.execute(str)
      end

      def quote(el)
        ::ApplicationRecord.quote(el)
      end

    end # ChelImport
  end # Parsers
end # VoshodAvtoExchange
