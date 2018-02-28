$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "simplecov"
SimpleCov.start

require "kafka_migrations"
require "active_support/all"
require "fakefs/safe"
require "fakefs/spec_helpers"

logger = Logger.new("log/test.log", :debug)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.before do
    KafkaMigrations.reset!
    KafkaMigrations.configure do |migrations_config|
      migrations_config.logger = logger
    end
  end
end
