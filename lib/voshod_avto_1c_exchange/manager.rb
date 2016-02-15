module VoshodAvtoExchange

  module Manager

    extend self

    STAT_INFO_S = %Q(
      [Обработка файла]: %{file}
      [Время старта]:    %{time}
    ).freeze

    STAT_INFO_E = %Q(
      [Завершена обработка файла]: %{file}
      [Затрачено времени]:         %{time}
    ).freeze

    def run

      extract_zip_files
      processing

    end # run

    private

    def import_dir
      ::VoshodAvtoExchange::import_dir
    end # import_dir

    def log(msg)
      ::VoshodAvtoExchange.log(msg, self.name)
    end # log

    def processing

      files = ::Dir.glob( ::File.join(import_dir, "**", "*.xml") )

      # Сортируем по дате последнего доступа по-возрастанию
      files.sort{ |a, b| ::File.new(a).mtime <=> ::File.new(b).atime }.each do |xml_file|

        start = ::Time.now.to_i

        log(STAT_INFO_S % {
          file: xml_file,
          time: ::Time.now
        })

        ::VoshodAvtoExchange::Parser.parse(xml_file)

        log(STAT_INFO_E % {
          file: xml_file,
          time: ::VoshodAvtoExchange::humanize_time(::Time.now.to_i - start)
        })

        ::FileUtils.rm_rf(xml_file)

      end # each

      self

    end # processing

    # Ищем и распаковываем все zip-архивы, после - удаляем
    def extract_zip_files

      i     = 0
      files = ::Dir.glob( ::File.join(import_dir, "**", "*.zip") )

      files.each do |zip|

        i+= 1
        begin

          ::Zip::File.open(zip) { |zip_file|

            zip_file.each { |f|

              # Создаем дополнительную вложенность т.к. 1С 8 выгружает всегда одни и теже
              # навания файлов, и если таких выгрузок будет много, то при распковке файлы
              # будут перезатираться

              f_path = ::File.join(
                import_dir,
                "#{i}",
                f.file? ? "#{rand}-#{::Time.now.to_f}-#{f.name}" : f.name
              )

              ::FileUtils.rm_rf(f_path) if ::File.exist?(f_path)
              ::FileUtils.mkdir_p(::File.dirname(f_path))

              zip_file.extract(f, f_path)

            } # each

          } # open

          ::FileUtils.rm_rf(zip)

        rescue => e
          log(e)
        end

      end # Dir.glob

      self

    end # extract_zip_files

  end # Manager

end # VoshodAvtoExchange
