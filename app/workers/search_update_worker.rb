class SearchUpdateWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform

    # Удаляем все из поискового индекса
    ::Item.clear_all_from_sphinx

    sleep 5

    # Обновляем поисковый индекс
    ::Item.insert_sphinx_by_page

    ensure
      ::SidekiqQuery.close(self.jid)
      ::GC.start

  end # perform

end # SearchUpdateWorker
