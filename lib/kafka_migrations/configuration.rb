module KafkaMigrations
  class Configuration
    attr_writer :migrations_topic_name,
                :seed_brokers,
                :logger

    #IVAR_REGEX = /^[a-z0-9_]+$/.freeze

    # TODO: use openstruct as delegate

    DEFAULTS = OpenStruct.new(num_partitions: 1,
                              replication_factor: 1,
                              topic_config: {}.freeze,
                              timeout: 30).freeze

    def configure
      yield self
    end

    def method_missing(name, *_args, &_blk)
      instance_variable_get("@#{name}") ||
        rails_config_kafka_migrations_value(name) ||
        config_data_value(name) ||
        DEFAULTS.public_send(name) ||
        nil
    end

    def respond_to_missing?(name, include_private = false)
      #(name.match?(IVAR_REGEX) && instance_variable_defined?("@#{name}")) ||
      methods.include?(:"#{name}=") ||
        (defined?(Rails) && Rails.configuration.kafka_migrations.key?(name)) ||
        config_data.key?(name) ||
        DEFAULTS.respond_to?(name) ||
        super
    end

    private

    def config_data
      @config_data ||= load_config_data
    end

    def config_data_value(name)
      config_data.key?(name) && config_data[name]
    end

    def load_config_data
      return {}.freeze unless File.exist?(config_file_path.to_s)

      YAML.safe_load(File.read(config_file_path), [], [], true).
        fetch(Rails.env).with_indifferent_access
    end

    def config_file_path
      # TODO: allow this to be set from config first?
      @config_file_path ||= defined?(Rails) && "#{Rails.application.root}/config/kafka.yml"
    end

    def rails_config_kafka_migrations_value(name)
      defined?(Rails) &&
      Rails.configuration.kafka_migrations.key?(name) &&
        Rails.configuration.kafka_migrations.send(name)
    end
  end
end
