class SearchUpdateWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform

    # Удаляем поисковый индекс
    ::Anubis.sql("TRUNCATE RTINDEX items")

    # Обновляем поисковый индекс
    ::Item.all.map(&:insert_sphinx)

    ensure
      ::SidekiqQuery.close(self.jid)

  end # perform

end # SearchUpdateWorker
