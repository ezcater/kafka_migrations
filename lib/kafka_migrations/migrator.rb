module KafkaMigrations
  class Migrator
    MigrationFilenameRegexp = /\A([0-9]+)_([_a-z0-9]*)\.?([_a-z0-9]*)?\.rb\z/

    # MigrationProxy is used to defer loading of the actual migration classes
    # until they are needed
    MigrationProxy = Struct.new(:name, :version, :filename) do
      def initialize(name, version, filename)
        super
        @migration = nil
      end

      def basename
        File.basename(filename)
      end

      def migrate(direction)
        migration.migrate(direction)
      end

      private

      def migration
        @migration ||= load_migration
      end

      def load_migration
        require(File.expand_path(filename))
        name.constantize.new(name, version)
      end
    end

    class << self
      def migrate
        up
      end

      def up
        new(:up).migrate
      end
    end

    attr_reader :direction

    def initialize(direction)
      @direction = direction
    end

    def migrate
      # TODO: validation on migrations
      # TODO: reverse migration order for down?
      runnable.each do |migration|
        execute_migration(migration, direction)
      end
    end

    private

    def logger
      KafkaMigrations.logger
    end

    def up?
      direction == :up
    end

    def down?
      direction == :down
    end

    def execute_migration(migration, direction)
      return if down? && !migrated.include?(migration.version)
      return if up? && migrated.include?(migration.version)

      logger.info("Migrating to #{migration.name} (#{migration.version})") if logger.present?

      migration.migrate(direction)
      record_version_after_migrating(migration.version)
    rescue StandardError => ex
      msg = "An error has occurred, this and all later migrations canceled:\n\n#{ex}"
      raise StandardError, msg, ex.backtrace
    end

    def record_version_after_migrating(version)
      if down?
        migrated.delete(version)
        MigrationsTopic.delete(version)
      else
        migrated << version
        MigrationsTopic.append(version)
      end
    end

    def migrations
      migration_files.map do |file|
        version, name, _scope = parse_migration_filename(file)
        version = version.to_i
        name = name.camelize

        MigrationProxy.new(name, version, file)
      end.sort_by!(&:version)
    end

    def parse_migration_filename(filename)
      File.basename(filename).scan(MigrationFilenameRegexp).first
    end

    def migration_files
      Dir["kafka/migrate/**/[0-9]*_*.rb"]
    end

    def migrated
      @migrated_versions ||= migrated_versions
    end

    def migrated_versions
      Set.new(load_migrated_versions)
    end

    def load_migrated_versions
      MigrationsTopic.all_versions
    end

    def ran?(migration)
      migrated.include?(migration.version)
    end

    def runnable
      migrations.reject { |m| ran?(m) }
    end
  end
end
