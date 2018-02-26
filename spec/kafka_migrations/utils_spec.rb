RSpec.describe KafkaMigrations::Utils do
  describe ".topic?" do
    let(:kafka) { instance_double(Kafka::Client) }
    let(:name) { "test-topic" }

    before do
      allow(Kafka).to receive(:new).and_return(kafka)
      KafkaMigrations.config.auto_create_enabled = auto_create
    end

    context "when auto_create_enabled is true" do
      let(:auto_create) { true }

      before do
        allow(kafka).to receive(:topics).and_return([])
      end

      it "gets the list of all topics from the Kafka client" do
        described_class.topic?(name)
        expect(kafka).to have_received(:topics)
      end
    end

    context "when auto_create_enabled is false" do
      let(:auto_create) { false }

      before do
        allow(kafka).to receive(:has_topic?)
      end

      it "uses the Kafka client to check if the topic exists" do
        described_class.topic?(name)
        expect(kafka).to have_received(:has_topic?).with(name)
      end
    end
  end
end
