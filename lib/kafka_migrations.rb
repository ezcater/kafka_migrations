require "ruby-kafka"
require "kafka_migrations/version"
require "kafka_migrations/migration"
require "kafka_migrations/migrations_topic"
require "kafka_migrations/tasks"
require "kafka_migrations/configuration"

require "kafka_migrations/railtie" if defined?(Rails)

module KafkaMigrations
  @config = Configuration.new

  class << self
    attr_reader :config

    def configure
      yield config
    end

    def client
      @client ||= Kafka.new(seed_brokers: config.seed_brokers,
                            sasl_plain_username: config.sasl_plain_username,
                            sasl_plain_password: config.sasl_plain_password,
                            ssl_ca_cert_file_path: config.ssl_ca_cert_file_path,
                            logger: logger)
    end

    def logger
      config.logger
    end

    # For testing
    def reset!
      @client = nil
      @config = Configuration.new
    end
  end
end
