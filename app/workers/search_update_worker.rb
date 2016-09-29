class SearchUpdateWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform

    # Обновляем поисковый индекс
    ::Item.insert_sphinx_by_page

    ensure
      ::SidekiqQuery.close(self.jid)
      ::GC.start

  end # perform

end # SearchUpdateWorker
