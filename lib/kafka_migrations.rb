require "ruby-kafka"
require "kafka_migrations/version"
require "kafka_migrations/migration"
require "kafka_migrations/migrations_topic"
require "kafka_migrations/tasks"

require "kafka_migrations/railtie" if defined?(Rails)

module KafkaMigrations
  class << self
    attr_accessor :migrations_topic_name,
                  :seed_brokers,
                  :logger

    def client
      @client ||= Kafka.new(seed_brokers: seed_brokers,
                            logger: logger)
    end
  end
end
