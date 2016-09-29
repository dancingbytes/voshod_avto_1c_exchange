class PriceGenerateWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform

    # Генерим прайс
    ::PriceList.generate

    ensure
      ::SidekiqQuery.close(self.jid)
      ::GC.start

  end # perform

end # PriceGenerateWorker
