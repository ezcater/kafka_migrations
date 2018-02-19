module Kafka
  class MigrationGenerator < Rails::Generators::NamedBase
    source_paths << File.join(__dir__, "templates")

    def create_migration_file
      template("migration_template.rb.erb", migration_file_path)
    end

    private

    def migration_timestamp
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def migration_file_path
      "kafka/migrate/#{migration_timestamp}_#{file_name}.rb"
    end
  end
end
