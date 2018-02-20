module KafkaMigrations
  class Railtie < Rails::Railtie
    config.kafka_migrations = ActiveSupport::OrderedOptions.new

    rake_tasks do
      load("#{__dir__}/tasks/kafka.rake")
    end
  end
end
