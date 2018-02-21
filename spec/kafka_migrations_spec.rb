RSpec.describe KafkaMigrations do
  it "has a version number" do
    expect(KafkaMigrations::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields the configuration" do
      expect do |blk|
        described_class.configure(&blk)
      end.to yield_with_args(described_class.config)
    end
  end

  describe ".client" do
    let(:mock_kafka) { instance_double(Kafka::Client) }
    let(:seed_brokers) { %w(seed_brokers) }
    before do
      described_class.config.seed_brokers = seed_brokers
      allow(Kafka).to receive(:new).and_return(mock_kafka)
    end

    it "returns a Kafka client" do
      described_class.client
      expect(Kafka).to have_received(:new).
        with(including(seed_brokers: seed_brokers))
    end

    it "memoizes the client" do
      client = described_class.client
      expect(described_class.client).to equal(client)
      expect(Kafka).to have_received(:new).once
    end
  end

  describe ".logger" do
    let(:config) { described_class.config }
    let(:mock_logger) { instance_double(Logger) }

    before do
      allow(config).to receive(:logger).and_return(mock_logger)
    end

    it "returns the logger from the configuration" do
      expect(described_class.logger).to eq(mock_logger)
      expect(config).to have_received(:logger)
    end
  end
end
