RSpec.describe KafkaMigrations::Migration do
  let(:kafka) { instance_double(Kafka::Client) }
  let(:migration_class) do
    Class.new(described_class)
  end
  let(:name) { "TestMigration" }
  let(:version) { Time.now.utc.strftime("%Y%m%d%H%M%S") }
  let(:migration) { migration_class.new(name, version) }
  let(:direction) { :up }

  before do
    allow(Kafka).to receive(:new).and_return(kafka)
    allow(KafkaMigrations::MigrationsTopic).to receive(:create)
  end

  describe ".new" do
    it "ensures that the MigrationsTopic is created" do
      migration
      expect(KafkaMigrations::MigrationsTopic).to have_received(:create)
    end
  end

  describe "#migrate" do
    before do
      allow(KafkaMigrations::MigrationsTopic).to receive(:create)
    end

    context "when the migration implements #change" do
      before do
        migration_class.class_eval do
          def change; end
        end
        allow(migration).to receive(:change)
      end

      it "calls #change" do
        migration.migrate(direction)
        expect(migration).to have_received(:change)
      end
    end

    context "when the migration does not implement #change" do
      context "when the direction is :up" do
        context "when the migration implements up" do
          before do
            migration_class.class_eval do
              def up; end
            end
            allow(migration).to receive(:up)
          end

          it "calls #up" do
            migration.migrate(direction)
            expect(migration).to have_received(:up)
          end
        end
      end

      context "when the direction is :down" do
        let(:direction) { :down }
        context "when the migration implements #down" do
          before do
            migration_class.class_eval do
              def down; end
            end
            allow(migration).to receive(:down)
          end

          it "calls #down" do
            migration.migrate(direction)
            expect(migration).to have_received(:down)
          end
        end
      end
    end
  end

  describe "#create_topic" do
    let(:topic_name) { "test-topic" }

    before do
      allow(kafka).to receive(:create_topic)
      KafkaMigrations.configure do |config|
        config.num_partitions = 5,
        config.replication_factor = 3,
        config.timeout = 7,
        config.topic_config = { "cleanup.policy" => "compact" }
      end
    end

    it "creates the topic" do
      migration.create_topic(topic_name, num_partitions: 4, timeout: 10)
      expect(kafka).to have_received(:create_topic).
        with(topic_name,
             num_partitions: 4,
             replication_factor: 3,
             timeout: 10,
             config: { "cleanup.policy" => "compact" })
    end
  end

  describe "#delete_topic" do
    let(:topic_name) { "test-topic" }
    let(:timeout) { rand(1..10) }

    before do
      KafkaMigrations.config.timeout = timeout
      allow(kafka).to receive(:delete_topic)
    end

    it "deletes the topic" do
      migration.delete_topic(topic_name)
      expect(kafka).to have_received(:delete_topic).with(topic_name, timeout: timeout)
    end
  end

  describe "#topic_exists?" do
    let(:topic_name) { "test-topic" }

    before do
      allow(KafkaMigrations::Utils).to receive(:topic?)
    end

    it "checks if the topic exists" do
      migration.topic_exists?(topic_name)
      expect(KafkaMigrations::Utils).to have_received(:topic?).with(topic_name)
    end
  end
end
