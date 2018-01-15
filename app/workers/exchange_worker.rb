class ExchangeWorker

  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def expiration
    @expiration = 60 * 60 * 24 * 1 # 1 day
  end

  def perform(file_path)

    ::VoshodAvtoExchange::Manager.run(

      file_path: file_path,

      init_clb: ->(msg) {
        at(0, msg)
      },

      start_clb: ->(req_total, msg) {
        total(req_total)
        at(0, msg)
      },

      process_clb: ->(index, msg) {
        at(index, msg)
      },

      completed_clb: ->(req_total, msg) {
        at(req_total, msg)
      }

    )

    ::SidekiqQuery.close(self.jid)

    rescue Exception => ex

      ::SidekiqQuery.close(self.jid, true)
      ::Rails.logger.warn(ex)

    ensure
      ::GC.start

  end # perform

end # ExchangeWorker
