RSpec.describe KafkaMigrations::Configuration do
  let(:config) { described_class.new }

  it "allows predefined config options to be set and read" do
    topic_name = "topic-name"
    config.migrations_topic_name = topic_name
    expect(config.migrations_topic_name).to eq(topic_name)
  end

  it "allows new configuration options to be added" do
    value = "added"
    config.try(:new_test_value=, value)
    expect(config.new_test_value).to eq(value)
  end

  it "returns nil for unknown config options" do
    expect(config.foobar).to be_nil
  end

  context "defaults" do
    it "defaults num_partitions for topics to 1" do
      expect(config.num_partitions).to eq(1)
    end

    it "defaults replication_factor for topics to 1" do
      expect(config.replication_factor).to eq(1)
    end

    it "defaults topic_config to an empty hash" do
      expect(config.topic_config).to eq(Hash.new)
    end

    it "defaults timeout to 30" do
      expect(config.timeout).to eq(30)
    end
  end

  context "order of precedence" do
    let(:num_partitions) { rand(10..100) }

    context "when a value is set in the KafkaMigrations configuration" do
      before do
        config.configure do |config_obj|
          config_obj.num_partitions = num_partitions
        end
      end

      it "uses the value from KafkaMigrations configuration" do
        expect(config.num_partitions).to eq(num_partitions)
      end
    end

    context "when Rails is present a value is set in Rails configuration" do
      let(:rails_module) do
        Module.new do
          def self.configuration
            @configuration ||= ActiveSupport::OrderedOptions.new.tap do |options|
              options.kafka_migrations = ActiveSupport::OrderedOptions.new
            end
          end
        end
      end

      before do
        stub_const("Rails", rails_module)
        rails_module.configuration.kafka_migrations.num_partitions = num_partitions
      end

      it "uses the value from Rails configuration" do
        expect(config.num_partitions).to eq(num_partitions)
      end
    end

    context "when there is a config file" do
      include FakeFS::SpecHelpers

      let(:config_file) { File.join(__dir__, "test_config", "kafka.yml") }

      before do
        FileUtils.mkdir_p(File.dirname(config_file))
        File.write(config_file, "num_partitions: #{num_partitions}")
        config.config_file = config_file
      end

      it "uses the value from the config file" do
        expect(config.num_partitions).to eq(num_partitions)
      end
    end

    context "when there is a config file with Rails" do
      include FakeFS::SpecHelpers

      let(:rails_module) do
        Module.new do
          def self.configuration
            ActiveSupport::OrderedOptions.new(kafka_migrations: {})
          end

          def self.application
            OpenStruct.new(root: __dir__)
          end

          def self.env
            "test"
          end
        end
      end
      let(:config_file) { File.join(__dir__, "config", "kafka.yml") }

      before do
        stub_const("Rails", rails_module)

        FileUtils.mkdir_p(File.dirname(config_file))
        File.write(config_file, <<~YML)
          default: &default
            num_partitions: 2
          development:
            <<: *default
          test:
            <<: *default
            num_partitions: #{num_partitions}
        YML
      end

      it "uses the value for the Rails environment" do
        expect(config.num_partitions).to eq(num_partitions)
      end
    end
  end
end
