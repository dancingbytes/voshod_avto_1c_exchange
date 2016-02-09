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
            save_catalogs_list
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
            parse_item(:id)         if item_only?
            parse_item(:catalog_id) if item_catalog?
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
            parse_item(:vendor_mog) if item_only?

          when "НомерГТД".freeze then
            parse_item(:gtd) if item_only?

          when "ДополнительноеОписаниеНоменклатуры".freeze then
            parse_item(:ext_param) if item_only?

          when "КодСтранаПроисхождения".freeze then
            parse_item(:contry_code) if item_only?

          when "СтранаПроисхождения".freeze then
            parse_item(:contry_name) if item_only?

          when "Производитель".freeze then
            parse_item(:vendor) if item_only?

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

      def end_document
        final_all
      end # end_document

      private

      #
      # Обработка каталогов
      #
      def start_catalogs

        @start_catalogs   = true
        @catalog          = {}
        @catalog_level    = 0
        @catalog_parents  = []
        @catalogs_list    = []

        # Характеристики товаров
        @items_features   = {}

        # Способ обновления товаров и каталогов
        @full_update      = false

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
          parent_id:  @catalog_parents[@catalog_level-1],
          p_id:       @provider_id
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

        # Добавляем каталог в список
        @catalogs_list << @catalog

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

      def save_catalogs_list

        #
        # Если значение @full_update:
        # true  -- полное обновление каталогов
        # false -- частичное обновление каталогов
        #

        @catalogs_list.each do |catalog|

          cat = ::Catalog.find_or_initialize_by(

            raw:          @full_update,
            p_id:         catalog[:p_id],
            p_catalog_id: catalog[:id]

          )

          cat.p_parent_id = catalog[:parent_id]
          cat.name        = catalog[:name]

          log(S_C_ERROR % {
            msg: cat.errors.full_messages
          }) unless cat.save

        end # each

      end # save_catalogs_list

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

      def save_item

        return if @item.nil? || @item.empty?

        item = ::Item.find_or_initialize_by(

          p_id:       @item[:p_id],
          p_item_id:  @item[:id]

        )

=begin
        :p_id=>"db996b9e-3d2f-11e1-84e7-00237d443107",
        :params=>{
          "ВидНоменклатуры"=>"Оптовый товар",
          "ТипНоменклатуры"=>"Товар",
          "Полное наименование"=>"Аккумулятор BOSCH S3 56 А/ч о.п ток 480 242х175х190",
          "Вес"=>"14.19"
        },
        :characters=>{
          "Марка"=>"BOSCH"
        },
        :id=>"b55a1516-38e0-11e3-afa4-003048f6ad92",
        :department=>"ГАЗ",
        :barcode=>"2000100907504",
        :mog=>"19268g",
        :name=>"Аккумулятор BOSCH S3 56 А/ч о.п ток 480 242х175х190",
        :contry_code=>"724",
        :contry_name=>"ИСПАНИЯ",
        :vendor=>"АКБ BOSCH",
        :price_group=>"fb8e53e8-d848-11e4-bf5f-003048f6ad92",
        :nom_group=>"f6c7fa61-e27e-11e2-a6bd-003048f6ad92",
        :unit_code=>"796",
        :unit=>"шт",
        :catalog_id=>"b55a166e-38e0-11e3-afa4-003048f6ad92"
        #
        #    ext_param
=end

        item.raw          = false
        item.p_catalog_id = @item[:catalog_id]
        item.nom_group    = @item[:nom_group]
        item.price_group  = @item[:price_group]
        item.mog          = @item[:mog]
        item.name         = @item[:name]
        item.vendor_mog   = @item[:vendor_mog]
        item.vendor       = @item[:vendor]
        item.brand        = @item[:characters]["Марка"]
        item.unit         = @item[:unit]
        item.unit_code    = @item[:unit_code]
        item.gtd          = @item[:gtd]
        item.barcode      = @item[:barcode]
        item.department   = @item[:department]
        item.contry_code  = @item[:contry_code]
        item.contry_name  = @item[:contry_name]
        item.weight       = @item[:params]["Вес"].try(:to_f)

        log(S_I_ERROR % {
          msg: item.errors.full_messages
        }) unless item.save

      end # save_item

      #
      # Начало обработки товаров
      #
      def start_work_with_items

        # При полной обработке данных, помечаем все товары как "сырые",
        # что бы в дальнейшем понять какие товары нужно удалит из каталога
        if @full_update

          ::Item.
            by_provider(@provider_id).
            update_all({ raw: true })

        end # if

      end # start_work_with_items

      #
      # Окончание операции по обработке данных
      #
      def final_all

        if @full_update

          # Удаляем все актуальные данные
          ::Catalog.
            by_provider(@provider_id).
            actual.
            delete_all

          # Все "сырые" данные делаем актуальными
          ::Catalog.
            by_provider(@provider_id).
            raw.
            update_all({ raw: false })

          # Удалем все товары у которых не указан каталог
          ::Item.
            by_provider(@provider_id).
            where({ p_catalog_id: nil }).
            delete_all

          # Удаляем все товары, которые не были обработаны
          ::Item.
            by_provider(@provider_id).
            raw.
            delete_all

        end # if

      end # final_all

    end # ChelImport

  end # Parsers

end # VoshodAvtoExchange