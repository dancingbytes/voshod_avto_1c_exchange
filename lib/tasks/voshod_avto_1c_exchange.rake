namespace :voshod_avto_1c_exchange do

  desc 'Обработка выгрузки'
  task :run => :environment do
    ::VoshodAvtoExchange.run
  end # run

end # voshod_avto_1c_exchange

# bundle exec rake voshod_avto_1c_exchange:run
