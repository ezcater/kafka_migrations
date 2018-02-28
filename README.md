# kafka_migrations

This gem provides functionality for managing Kafka configuration via migrations
similar to ActiveRecord migrations

## Installation

Add this line to your application's Gemfile:

```ruby
gem "kafka_migrations"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kafka_migrations

## Usage

### Configuration

Configuration used by the gem can be set in multiple places. The order of
precedence in which different configuration options are used is:

1. Values set directly in `KafkaMigrations`' configuration using
  `KafkaMigrations.configure(&blk)` or `KafkaMigrations.config.configure(&blk)`.
1. Values set as part of `Rails.configuration.kafka_migrations` if Rails is used.
1. Values set in a YAML configuration file. In a Rails application, this file's
  location defaults to `#{Rails.root}/config/kafka.yml`. The location for this
  file can be configured using one of the previous options as `config_file`.
1. Defaults from the gem.

The configuration used by the gem is extensible so that additional option names
and values can be added and referenced within migrations. The builtin options
used by the gem are:

TODO: option descriptions

* **migrations_topic_name**:
* **seed_brokers**:
* **logger**:
* **sasl_plain_username**:
* **sasl_plain_password**:
* **ssl_ca_cert_file_path**:
* **config_file**:
* **config_environment**:
* **auto_create_enabled**:
* **num_partitions**:
* **replication_factor**:
* **topic_config**:
* **timeout**:

### Creating migrations

Migrations can be created by run the rails generator `kafka:migration`:

```bash
rails generate kafka:migration CreateDemoTopic
      create  kafka/migrate/20180219145400_create_demo_topic.rb
```

The migration file will be created in the `kafka/migrate` directory and will be
prefixed with a timestamp that is used to determine the order of migrations.

#### Migration methods

The following methods are supported in migrations:

* `create_topic(name, num_partitions: 1, replication_factor: 1, timeout: 30, config: {})`
* `delete_topic(name)`
* `topic_exists?(name)`

#### Defining migrations

**Note: Only `up` migrations are currently supported.**

Migrations can define either a `change` method or `up` and `down` method.

```ruby
# kafka/migrate/20180219145400_create_demo_topic.rb
class CreateDemoTopic < KafkaMigrations::Migration
  def up
    create_topic("demo-topic")
  end 
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org)
.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ezcater/kafka_migrations.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

