module KafkaMigrations
  module Utils
    class << self

      # If the cluster has auto-create enabled, then
      # Kafka::Client#has_topic? will create the topic.
      def topic?(name)
        if KafkaMigrations.config.auto_create_enabled
          client.topics.include?(name)
        else
          client.has_topic?(name)
        end
      end

      private

      def client
        KafkaMigrations.client
      end
    end
  end
end
