RSpec.describe KafkaMigrations::Tasks do
  describe ".migrate" do
    before do
      allow(KafkaMigrations::Migrator).to receive(:migrate)
    end

    it "calls Migrator.migrate" do
      described_class.migrate
      expect(KafkaMigrations::Migrator).to have_received(:migrate)
    end
  end
end
