module KafkaMigrations
  class Configuration
    def method_missing(name)
      KafkaMigrations.try(name) ||
        (Rails.configuration.kafka_migrations.key?(name) && Rails.configuration.kafka_migrations.send(name)) ||
        (config_data.key?(name) && config_data[name])
    end

    private

    def config_data
      # TODO: exists check!
      @config_data ||= YAML.load(File.read("#{Rails.application.root}/config/kafka.yml")).
        fetch(Rails.env).with_indifferent_access
    end
  end
end
