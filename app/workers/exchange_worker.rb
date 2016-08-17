class ExchangeWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform(file_path)

    ::VoshodAvtoExchange::Manager.run(

      file_path: file_path,

      init_clb: ->(msg) {
        at(0, msg)
      },

      start_clb: ->(total, msg) {
        self.total = total
        at(0, msg)
      },

      process_clb: ->(index, msg) {
        at(index, msg)
      },

      completed_clb: ->(total, msg) {
        at(total, msg)
      }

    )

    ensure
      ::SidekiqQuery.close(self.jid)

  end # perform

end # ExchangeWorker
