module KafkaMigrations
  class Migration
    attr_reader :name, :version

    def initialize(name, version)
      @name = name
      @version = version

      MigrationsTopic.create
    end

    def migrate(direction)
      case direction
      when :up   then announce "migrating"
      when :down then announce "reverting"
      end

      time = Benchmark.measure do
        exec_migration(direction)
      end

      case direction
      when :up   then announce "migrated (%.4fs)" % time.real; write
      when :down then announce "reverted (%.4fs)" % time.real; write
      end
    end


    def create_topic(name, num_partitions: nil, replication_factor: nil, timeout: nil, config_entries: {})
      # TODO: direction
      # TopicCreator class? Or CommandRecorder
      num_partitions ||= 1
      replication_factor ||= 1
      timeout ||= 30
      client.create_topic(name,
                          num_partitions: num_partitions,
                          replication_factor: replication_factor,
                          timeout: timeout,
                          config_entries: config_entries)
      write("created topic name: #{name.inspect}, partitions: #{num_partitions}, "\
            "replicas: #{replication_factor}, config_entries: #{config_entries}")
    end

    def delete_topic(name, timeout: nil)
      client.delete_topic(name, timeout: timeout || 30)
      write("deleted topic name: #{name}")
    end

    def topic_exists?(name)
      client.topics.include?(name)
    end

    private

    def exec_migration(direction)
      if respond_to?(:change)
        change
      elsif respond_to?(direction)
        send(direction)
      end
    end

    def client
      KafkaMigrations.client
    end

    def write(text = "")
      puts(text) # if verbose TODO
    end

    def announce(message)
      text = "#{version} #{name}: #{message}"
      length = [0, 75 - text.length].max
      write "== %s %s" % [text, "=" * length]
    end
  end
end
