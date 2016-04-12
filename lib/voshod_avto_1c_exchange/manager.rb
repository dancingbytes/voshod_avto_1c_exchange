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
      process_all

    end # run

    def sidekiq_run(
      file_path:,
      init_clb:       nil,
      start_clb:      nil,
      process_clb:    nil,
      completed_clb:  nil
    )

      init_clb      = ->(msg) {}        unless init_clb.is_a?(::Proc)
      start_clb     = ->(total, msg) {} unless start_clb.is_a?(::Proc)
      process_clb   = ->(index, msg) {} unless process_clb.is_a?(::Proc)
      completed_clb = ->(total) {}      unless completed_clb.is_a?(::Proc)

      # Распаковываем zip архив, если такой имеется.
      # Подготавливаем список файлов к обработке
      files = if is_zip?(file_path)
        init_clb.call("Распаковка: #{file_path}")
        extract_zip_file(file_path)
      else
        [file_path]
      end

      init_clb.call("Подсчет...")

      # Массив вида: название файла --> число строк
      hfl = {}
      files.each { |fl|
        # Число строк в файле
        hfl[fl] = count_lines(fl)
      }

      # Итоговое число строк
      total = hfl.values.sum

      start_clb.call(total, "Начало обработки.")

      line = 0
      files.each { |fl|
        line += process_file(fl, process_clb, line, hfl[fl])
      }

      completed_clb.call(total, "Обработка завершена.")

      self

    end # sidekiq_run

    private

    def import_dir
      ::VoshodAvtoExchange::import_dir
    end # import_dir

    def log(msg)
      ::VoshodAvtoExchange.log(msg, self.name)
    end # log

    # Обработка всех файлов в заданой директории
    def process_all

      files = ::Dir.glob( ::File.join(import_dir, "**", "*.xml") )

      # Сортируем по дате последнего доступа по-возрастанию
      files.sort{ |a, b| ::File.new(a).mtime <=> ::File.new(b).atime }.each do |xml_file|
        process_file(xml_file)
      end # each

      self

    end # process_all

    # Обработка файла
    def process_file(file_name, clb = nil, line = 0, total_lines = 0)

      return 0 unless File.exists?(file_name)

      start = ::Time.now.to_i

      log(STAT_INFO_S % {
        file: file_name,
        time: ::Time.now
      })

      lines = ::VoshodAvtoExchange::Parser.parse(file_name,
        clb:    clb,
        cstart: line,
        tlines: total_lines
      )

      log(STAT_INFO_E % {
        file: file_name,
        time: ::VoshodAvtoExchange::Util::humanize_time(::Time.now.to_i - start)
      })

      ::FileUtils.rm_rf(file_name)

      lines

    end # process_file

    # Число строк в файле
    def count_lines(file_name)

      return 0 unless File.exists?(file_name)
      ::VoshodAvtoExchange::LineCounter.count(file_name)

    end # count_lines

    # Ищем и распаковываем все zip-архивы, после - удаляем
    def extract_zip_files

      files = ::Dir.glob( ::File.join(import_dir, "**", "*.zip") )

      files.each do |zip|
        extract_zip_file(zip)
      end # Dir.glob

      self

    end # extract_zip_files

    def extract_zip_file(file_name)

      files = []
      begin

        ::Zip::File.open(file_name) { |zip_file|

          zip_file.each { |f|

            # Создаем дополнительную вложенность т.к. 1С 8 выгружает всегда одни и теже
            # навания файлов, и если таких выгрузок будет много, то при распковке файлы
            # будут перезатираться

            f_path = ::File.join(
              import_dir,
              f.file? ? "#{rand}-#{::Time.now.to_f}-#{f.name}" : f.name
            )

            files << f_path

            ::FileUtils.rm_rf(f_path) if ::File.exist?(f_path)
            ::FileUtils.mkdir_p(::File.dirname(f_path))

            zip_file.extract(f, f_path)

          } # each

        } # open

        ::FileUtils.rm_rf(zip)

      rescue => e
        log(e)
      end

      files

    end # extract_zip_file

    def is_zip?(file_name)

      begin
        ::Zip::File.open(file_name) { |zip_file| }
        true
      rescue
        false
      end

    end # is_zip?

  end # Manager

end # VoshodAvtoExchange
