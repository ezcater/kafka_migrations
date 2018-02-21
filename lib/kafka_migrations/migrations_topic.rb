module KafkaMigrations
  class MigrationsTopic
    TOPIC_CONFIG = { "cleanup.policy" => "compact".freeze }.freeze

    class << self
      def create
        return if has_topic?(name)

        client.create_topic(name,
                            num_partitions: 1,
                            config: TOPIC_CONFIG)
      end

      # If the cluster has auto-create enabled, then
      # Kafka::Client#has_topic? will create the topic.
      def has_topic?(name)
        client.topics.include?(name)
      end

      def name
        @name ||= KafkaMigrations.config.migrations_topic_name ||
          "_#{Rails.application.class.parent.name.underscore}_migrations"
      end

      def all_versions
        versions = Set.new
        return versions unless has_topic?(name)

        offset = :earliest

        loop do
          messages = client.fetch_messages(
            topic: name,
            partition: 0,
            offset: offset,
            min_bytes: 0
          )

          messages.each do |message|
            version = message.key.to_i

            if message.value.nil?
              versions.delete(version)
            else
              versions << version
            end

            offset = message.offset + 1
          end

          break if messages.empty?
        end

        versions
      end

      def delete(version)
        client.deliver_message(nil, key: version.to_s, topic: name, partition: 0)
      end

      def append(version)
        version_str = version.to_s
        client.deliver_message(version_str, key: version_str, topic: name, partition: 0)
      end

      private

      def client
        KafkaMigrations.client
      end
    end
  end
end
