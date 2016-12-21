class SearchUpdateWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform

    # Удаляем все из поискового индекса
    ::Item.clear_sphinx

    sleep 3

    # Обновляем поисковый индекс
    ::Item.insert_sphinx

    ensure
      ::SidekiqQuery.close(self.jid)
      ::GC.start

  end # perform

end # SearchUpdateWorker
