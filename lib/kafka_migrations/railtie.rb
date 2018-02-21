module KafkaMigrations
  class Railtie < Rails::Railtie
    config.kafka_migrations = ActiveSupport::OrderedOptions.new

    rake_tasks do
      load("#{__dir__}/tasks/kafka.rake")
    end

    initializer "kafka_migrations.initialize" do
      KafkaMigrations.configure do |config|
        config.logger = Rails.logger
      end
    end
  end
end
