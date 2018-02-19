require "kafka_migrations"

namespace :kafka do
  desc "Run pending Kafka migrations"
  task migrate: [:environment] do
    KafkaMigrations::Tasks.migrate
  end
end
