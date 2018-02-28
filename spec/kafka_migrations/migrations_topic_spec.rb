RSpec.describe KafkaMigrations::MigrationsTopic do
  let(:kafka) { instance_double(Kafka::Client) }
  let(:topic_name) { described_class.topic_name }

  before do
    allow(KafkaMigrations).to receive(:client).and_return(kafka)
  end

  describe ".create" do
    before do
      allow(KafkaMigrations::Utils).to receive(:topic?).and_return(topic_exists)
    end

    context "when the topic does not exist" do
      let(:topic_exists) { false }

      before do
        allow(kafka).to receive(:create_topic)
      end

      it "creates the topic" do
        described_class.create
        expect(kafka).to have_received(:create_topic).
          with(topic_name, num_partitions: 1, config: { "cleanup.policy" => "compact" })
      end
    end

    context "when the topic already exists" do
      let(:topic_exists) { true }
      let(:cleanup_policy) { "compact" }
      let(:describe_response) do
        Hash["cleanup.policy" => cleanup_policy]
      end

      before do
        allow(kafka).to receive(:describe_topic).and_return(describe_response)
      end

      it "checks that the topic is defined correctly" do
        described_class.create
        expect(kafka).to have_received(:describe_topic).
          with(topic_name, %w(cleanup.policy))
      end

      context "when the topic does not have the expect configuration" do
        let(:cleanup_policy) { "delete" }

        it "raises an error" do
          expect do
            described_class.create
          end.to raise_error(described_class::CleanupPolicyError,
                             "cleanup.policy for migrations topic #{topic_name.inspect} must be 'compact'")
        end
      end
    end
  end

  describe ".topic_name" do
    context "when a name is available via KafkaMigrations config" do
      let(:topic_name) { "config-topic" }

      before do
        allow(KafkaMigrations.config).to receive(:migrations_topic_name).
          and_return(topic_name)
      end

      it "returns the config topic name" do
        expect(described_class.topic_name).to eq(topic_name)
      end
    end

    context "when Rails is defined" do
      let(:rails_module) do
        Module.new do
          def self.configuration
            OpenStruct.new(kafka_migrations: {})
          end

          def self.application; end
        end
      end
      let(:app_module) do
        Module.new do
          def self.name
            "MyApplication"
          end
        end
      end

      before do
        stub_const("Rails", rails_module)
        # rubocop:disable RSpec/MessageChain
        allow(rails_module).to receive_message_chain(:application, :root).
          and_return("./")
        allow(rails_module).to receive_message_chain(:application, :class, :parent).
          and_return(app_module)
        # rubocop:enable RSpec/MessageChain
      end

      it "returns the default Rails name" do
        expect(described_class.topic_name).to eq("_my_application_migrations")
      end
    end

    context "when no name is configured and Rails is not present" do
      it "returns the default topic name" do
        expect(described_class.topic_name).to eq("_kafka_migrations")
      end
    end
  end

  describe ".all_versions" do
    before do
      allow(KafkaMigrations::Utils).to receive(:topic?).and_return(topic_exists)
    end

    context "when topic does not exist" do
      let(:topic_exists) { false }

      it "returns an empty set" do
        expect(described_class.all_versions).to eq(Set.new)
      end
    end

    context "when the topic exists" do
      let(:version) { Time.now.utc.strftime("%Y%m%d%H%M%S") }
      let(:last_version) { (version.to_i + 1).to_s }
      let(:topic_exists) { true }
      let(:first_message_batch) do
        [
          Kafka::Protocol::Message.new(value: version.to_s, key: version.to_s, offset: 0)
        ]
      end
      let(:second_message_batch) do
        [
          Kafka::Protocol::Message.new(value: nil, key: version.to_s, offset: 1),
          Kafka::Protocol::Message.new(value: last_version.to_s, key: last_version.to_s, offset: 2)
        ]
      end
      let(:empty_batch) { Array.new }

      before do
        allow(kafka).to receive(:fetch_messages).
          and_return(first_message_batch, second_message_batch, empty_batch)
      end

      it "returns the undeleted versions" do
        expect(described_class.all_versions).to eq(Set.new([last_version.to_i]))
      end
    end
  end

  describe ".delete" do
    let(:version) { Time.now.utc.strftime("%Y%m%d%H%M%S") }

    before do
      allow(kafka).to receive(:deliver_message)
    end

    it "publishes the version with a nil value" do
      described_class.delete(version)
      expect(kafka).to have_received(:deliver_message).
        with(nil, key: version.to_s, topic: topic_name, partition: 0)
    end
  end

  describe ".append" do
    let(:version) { Time.now.utc.strftime("%Y%m%d%H%M%S") }

    before do
      allow(kafka).to receive(:deliver_message)
    end

    it "publishes the new version" do
      described_class.append(version)
      expect(kafka).to have_received(:deliver_message).
        with(version.to_s, key: version.to_s, topic: topic_name, partition: 0)
    end
  end
end
