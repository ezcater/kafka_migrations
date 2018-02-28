module KafkaMigrations
  class MigrationsTopic
    CLEANUP_POLICY = "cleanup.policy".freeze
    COMPACT = "compact".freeze
    TOPIC_CONFIG = { CLEANUP_POLICY => COMPACT }.freeze
    REQUIRED_CONFIGS = [CLEANUP_POLICY].freeze

    class CleanupPolicyError < StandardError
      def initialize(topic_name)
        super("cleanup.policy for migrations topic #{topic_name.inspect} must be 'compact'")
      end
    end

    class << self
      def create
        @created ||=
          if Utils.topic?(topic_name)
            check_config!
          else
            client.create_topic(topic_name,
                                num_partitions: 1,
                                config: TOPIC_CONFIG)
          end
      end

      def topic_name
        @topic_name ||= KafkaMigrations.config.migrations_topic_name ||
          (defined?(Rails) && rails_default_name) ||
          "_kafka_migrations".freeze
      end

      def all_versions
        versions = Set.new
        return versions unless Utils.topic?(topic_name)

        offset = :earliest

        loop do
          messages = client.fetch_messages(
            topic: topic_name,
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
        client.deliver_message(nil, key: version.to_s, topic: topic_name, partition: 0)
      end

      def append(version)
        version_str = version.to_s
        client.deliver_message(version_str, key: version_str, topic: topic_name, partition: 0)
      end

      # for test support
      def reset!
        @configs = nil
        @created = nil
        @topic_name = nil
      end

      private

      def check_config!
        @configs ||=
          client.describe_topic(topic_name, REQUIRED_CONFIGS).tap do |configs|
            raise CleanupPolicyError.new(topic_name) unless configs[CLEANUP_POLICY] == COMPACT
          end
      end

      def rails_default_name
        "_#{Rails.application.class.parent.name.underscore}_migrations"
      end

      def client
        KafkaMigrations.client
      end
    end
  end
end
