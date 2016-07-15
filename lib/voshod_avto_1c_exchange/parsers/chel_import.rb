#
# Обработка import-файла из 1С Челябинска
#
module VoshodAvtoExchange

  module Parsers

    class ChelImport < Base

      S_C_ERROR = %Q(Ошибка сохранения каталога в базу.
        %{msg}
      ).freeze

      S_I_ERROR = %Q(Ошибка сохранения товара в базу.
        %{msg}
      ).freeze

      def initialize(
        provider_id:  nil,
        doc_info:     {}
      )

        super

        @provider_id = provider_id
        @doc_info    = doc_info
        start_catalogs

      end # new

      def start_element(name, attrs = [])

        super

        case name

          when "Группы".freeze then
            start_subcatalogs_group
            add_catalog

          when "Группа".freeze  then
            up_catalog_level
            start_catalog_group

          when "Свойство".freeze then
            start_feature_params

          when "Каталог".freeze then
            update_mode
            stop_work_with_catalogs
            start_items
            start_work_with_items

          when "Товар".freeze then
            start_item

          when "ЗначениеРеквизита".freeze then
            start_item_param

          when "ЗначенияСвойства".freeze then
            start_item_character

        end # case

      end # start_element

      def end_element(name)

        super

        case name

          when "Классификатор".freeze   then
            stop_catalogs

          when "Ид".freeze              then
            # Каталоги
            parse_catalog(:id)
            parse_id_items_feature

            # Товары
            parse_item(:id)           if item_only?
            parse_item(:p_catalog_id) if item_catalog?
            parse_item_character(:key)

          when "Наименование".freeze    then
            # Каталоги
            parse_catalog(:name)
            parse_name_items_feature

            # Товары
            parse_item(:name)       if item_only?
            parse_item_param(:key)

          when "Группа".freeze   then
            down_catalog_level
            add_catalog

          when "Свойство".freeze then
            stop_feature_params

          when "Каталог".freeze then
            stop_items

          when "Товар".freeze then
            stop_item
            save_item

          when "Отдел".freeze then
            parse_item(:department) if item_only?

          when "Штрихкод".freeze then
            parse_item(:barcode) if item_only?

          when "Артикул".freeze then
            parse_item(:mog) if item_only?

          when "АртикулПроизводителя".freeze then
            parse_item(:oem_num) if item_only?

          when "НомерГТД".freeze then
            parse_item(:gtd) if item_only?

          when "ДополнительноеОписаниеНоменклатуры".freeze then
            parse_item(:ext_param) if item_only?

          when "КодСтранаПроисхождения".freeze then
            parse_item(:contry_code) if item_only?

          when "СтранаПроисхождения".freeze then
            parse_item(:contry_name) if item_only?

          when "Производитель".freeze then
            parse_item(:oem_brand) if item_only?

          when "ЦеноваяГруппа".freeze then
            parse_item(:price_group, attrs["ИД"]) if item_only?

          when "НоменклатурнаяГруппа".freeze then
            parse_item(:nom_group, attrs["ИД"]) if item_only?

          when "БазоваяЕдиница".freeze then
            parse_item(:unit_code, attrs["Код"]) if item_only?
            parse_item(:unit) if item_only?

          when "Значение".freeze then
            parse_item_param(:value)
            parse_item_character(:value)

          when "ЗначениеРеквизита".freeze then
            stop_item_param

          when "ЗначенияСвойства".freeze then
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
          p_parent_id:  @catalog_parents[@catalog_level-1],
          p_id:         @provider_id
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
        @full_update = ["true", true].include?(attrs["СодержитТолькоИзменения"])
      end # update_mode

      #
      # Обработка товаров
      #
      def start_items
        @start_items = true
      end # start_items

      def stop_items

        @start_items = false
        stop_work_with_items

      end # stop_items

      def start_item

        return unless @start_items

        @start_item = true
        @item       = {
          p_id:         @provider_id,
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
        for_item? && tag == "Товар".freeze
      end # item_only?

      def item_catalog?
        for_item? && tag == "Группы".freeze
      end # item_catalog?

      def item_character?
        for_item? && tag == "ЗначенияСвойства".freeze
      end # item_character?

      def item_param?
        for_item? && tag == "ЗначениеРеквизита".freeze
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

        cat = ::Catalog.find_or_initialize_by(

          p_id:         @catalog[:p_id],
          p_catalog_id: @catalog[:id]

        )

        # Сохраняем инднтификатор текущего каталога
        @catalogs_meta[@catalog[:id]] = cat.id.to_s

        # Выбираем идентификатор родительского каталога
        cat.parent_id   = @catalogs_meta[@catalog[:p_parent_id]]

        cat.raw         = false
        cat.p_parent_id = @catalog[:p_parent_id]
        cat.name        = @catalog[:name]

        begin

          log(S_C_ERROR % {
            msg: cat.errors.full_messages
          }) unless cat.save

        rescue => ex

          log(S_C_ERROR % {
            msg: ex.backtrace.join("\n")
          })

        end


      end # save_catalog

      def save_item

        return if @item.nil? || @item.empty?

        item = ::Item.find_or_initialize_by(

          p_id:       @item[:p_id],
          p_item_id:  @item[:id]

        )

        item.raw          = false
        item.updated_at   = ::Time.now.utc
        item.p_catalog_id = @item[:p_catalog_id]
        item.nom_group    = @item[:nom_group]
        item.price_group  = @item[:price_group]
        item.mog          = @item[:mog]
        item.name         = @item[:name]

        item.oem_num      = @item[:oem_num]
        item.oem_brand    = @item[:oem_brand]

        item.brand        = @item[:characters]["Марка"]
        item.unit         = @item[:unit]
        item.unit_code    = @item[:unit_code]
        item.gtd          = @item[:gtd]
        item.barcode      = @item[:barcode]
        item.contry_code  = @item[:contry_code]
        item.contry_name  = @item[:contry_name]
        item.weight       = @item[:params]["Вес"].try(:to_f)

        begin

          log(S_I_ERROR % {
            msg: item.errors.full_messages
          }) unless item.upsert

        rescue => ex

          log(S_I_ERROR % {
            msg: ex.backtrace.join("\n")
          })

        end

      end # save_item

      #
      # Начало обработки каталогов
      #
      def start_work_with_catalogs

        # При полной обработке данных, помечаем все каталоги как "сырые",
        # что бы в дальнейшем понять какие каталоги нужно удалит из каталога
        ::Catalog.
          by_provider(@provider_id).
          update_all({ raw: true })

      end # start_work_with_catalogs

      #
      # Окончание обработки каталогов
      #
      def stop_work_with_catalogs

        # Все "сырые" данные удаляем
        if @full_update

          ::Catalog.
            by_provider(@provider_id).
            raw.
            destroy_all

          ::Catalog.update_all({
            lft: 0,
            rgt: 0
          })

          ::Catalog.rebuild!

        else

          ::Catalog.
            by_provider(@provider_id).
            update_all({ raw: true })

        end # if

      end # stop_work_with_catalogs

      #
      # Начало обработки товаров
      #
      def start_work_with_items

        # При полной обработке данных, помечаем все товары как "сырые",
        # что бы в дальнейшем понять какие товары нужно удалит из каталога
        ::Item.
          by_provider(@provider_id).
          update_all({ raw: true })

      end # start_work_with_items

      #
      # Окончание обработки товаров
      #
      def stop_work_with_items

        if @full_update

          # Удалем все товары у которых не указан каталог
          ::Item.
            by_provider(@provider_id).
            where({ p_catalog_id: nil }).
            destroy_all

          # Удаляем все товары, которые не были обработаны
          ::Item.
            by_provider(@provider_id).
            raw.
            destroy_all

        else

          ::Item.
            by_provider(@provider_id).
            update_all({ raw: true })

        end # if

      end # stop_work_with_items

    end # ChelImport

  end # Parsers

end # VoshodAvtoExchange
