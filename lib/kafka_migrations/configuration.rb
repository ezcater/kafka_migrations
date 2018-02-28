require "ostruct"
require "private_attr"
require "yaml"

module KafkaMigrations
  class Configuration
    extend PrivateAttr

    CONFIG_OPTIONS = {
      migrations_topic_name: nil,
      seed_brokers: nil,
      logger: nil,
      sasl_plain_username: nil,
      sasl_plain_password: nil,
      ssl_ca_cert_file_path: nil,
      config_file: nil,
      auto_create_enabled: true,
      config_environment: nil
    }.freeze

    DEFAULTS = OpenStruct.new(num_partitions: 1,
                              replication_factor: 1,
                              topic_config: {}.freeze,
                              timeout: 30).freeze

    private_attr_reader :delegate

    def initialize
      @delegate = OpenStruct.new(CONFIG_OPTIONS)
    end

    def configure
      yield delegate
    end

    private

    # We want to return nil instead of calling super for method_missing.
    # rubocop:disable Style/MethodMissing
    def method_missing(name, *args, &_blk)
      if name.to_s.end_with?("=".freeze)
        delegate.send(name, *args)
      else
        method_missing_reader(name)
      end
    end
    # rubocop:enable Style/MethodMissing

    def respond_to_missing?(name, _include_private = false)
      if name.to_s.end_with?("=".freeze)
        true
      else
        respond_to_missing_reader?(name) || super
      end
    end

    def method_missing_reader(name)
      delegate.public_send(name) ||
        rails_config_kafka_migrations_value(name) ||
        config_data_value(name) ||
        DEFAULTS.public_send(name) ||
        nil
    end

    def respond_to_missing_reader?(name)
      delegate.respond_to?(name) ||
        (defined?(Rails) && Rails.configuration.kafka_migrations.key?(name)) ||
        config_data.key?(name) ||
        DEFAULTS.respond_to?(name)
    end

    def config_data
      @config_data ||= load_config_data
    end

    def config_data_value(name)
      config_data.key?(name) && config_data[name]
    end

    def load_config_data
      return {}.freeze unless File.exist?(config_file_path.to_s)

      data = YAML.safe_load(File.read(config_file_path), [], [], true)

      if config_data_environment.present?
        data.fetch(config_data_environment)
      else
        data
      end.with_indifferent_access
    end

    def config_data_environment
      @config_data_environment ||= delegate.config_environment || (defined?(Rails) && Rails.env)
    end

    def config_file_path
      if defined?(@config_file_path)
        @config_file_path
      else
        @config_file_path = delegate.config_file ||
                            rails_config_kafka_migrations_value("config_file".freeze) ||
                            (defined?(Rails) && "#{Rails.application.root}/config/kafka.yml")
      end
    end

    def rails_config_kafka_migrations_value(name)
      defined?(Rails) &&
        Rails.configuration.kafka_migrations.key?(name) &&
        Rails.configuration.kafka_migrations.send(name)
    end
  end
end
