require "kafka_migrations/migrator"

module KafkaMigrations
  module Tasks
    class << self
      def migrate
        Migrator.migrate
      end
    end
  end
end
