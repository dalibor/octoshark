![Octoshark logo](https://dl.dropboxusercontent.com/u/3230730/github/octoshark.png)

![Travis status](https://travis-ci.org/dalibor/octoshark.png)

Octoshark is a simple ActiveRecord connection manager. It provides a connection switching mechanism that can be used in various scenarios like: sharding, master-slave, multi-tenancy, etc. You have control over how connections are configured and used, see below for examples.


## Installation

Add this line to your application's Gemfile:

```
gem 'octoshark'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install octoshark
```


## Usage

Create a new connection manager with connection 2 pools for Octoshark to manage. This usually goes in the app initializer.

```ruby
CONN_MANAGER = Octoshark::ConnectionManager.new({
  db1: { adapter: "sqlite3", database: "db/db1.sqlite" },
  db2: { adapter: "sqlite3", database: "db/db2.sqlite" }
})
```

Configure which ActiveRecord model will use the Octoshark connection by overriding the `Model.connection` method.

```ruby
class Post < ActiveRecord::Base
  def self.connection
    CONN_MANAGER.current_connection
  end
end
```

Alternatively, extract it as a module and include in models.

```ruby
module ShardingModel
  extend ActiveSupport::Concern

  module ClassMethods
    def connection
      OCTOSHARK.current_connection
    end
  end
end
```

To use a specific database connection:

```ruby
CONN_MANAGER.with_connection(:db1) do
  # run queries on db1
  Post.first
end
```

Multiple `with_connection` blocks can be nested:

```ruby
CONN_MANAGER.with_connection(:db1) do
  # run queries on db1

  CONN_MANAGER.with_connection(:db2) do
    # run queries on db2
  end

  # run queries on db1
end
```

`CONN_MANAGER.current_connection` returns the active connection while in the `with_connection` block or raises `Octoshark::Error::NoCurrentConnection` otherwise.


## Sharding example

Some models are in the core DB, and others in shard DBs. Shard is selected based on a user attribute. For core models use the default ActiveRecord connection and for sharded models define and use Octoshark connections.

Switch the connection in a controller with an around filter:

```ruby
around_filter :select_shard

def select_shard(&block)
  CONN_MANAGER.with_connection(current_user.shard, &block)
end
```

Similar approach applies to other application entry-points like background jobs.


## Master-Slave example

All models are in master and slave databases. For master models use the default ActiveRecord connection and for slave models define and use Octoshark connections.

```ruby
class ActiveRecord::Base
  def self.connection
    # Return the current connection (from with_connection block) or default one
    CONN_MANAGER.current_or_default_connection
  end
end
```

`CONN_MANAGER.current_or_default_connection` method returns the current connection while in `with_connection` block or the default ActiveRecord connection when outside.


## Multi-tenant example

Some models are in the core DB, and others in user's own dedicated database. For core models use the default ActiveRecord connection and for tenant models can use Octoshark's mechanism to create new temporary connection.

Switch the connection in a controller with an around filter:

```ruby
# in initializer
CONN_MANAGER = Octoshark::ConnectionManager.new

# in controller
around_filter :select_shard

def select_shard(&block)
  CONN_MANAGER.with_new_connection(name, config, reusable: false, &block)
end
```

`CONN_MANAGER.with_new_connection` method creates a temporary connection that will automatically disconnect. If you want to reuse it in subsequent connection switches, set `reusable: true` and it will be added to the connection manager and reused with the next calls. Depends on the use-case and what's preferable. In test environment usually you would want to set it to `reusable` so that database cleaner can clean data with transaction strategy.

Alternatively, for better performance (only supported on MySQL), database connection can be switched with `use database` statement. Once connection manager is defined with connectino configs to database servers, selecting a database can be done with:

```ruby
CONN_MANAGER.use_database(:db1, 'database') do
  # run queries on database server identified by 'db1' using database 'database'
end
```

## Octoshark.reset_connection_managers!

Whenever ActiveRecord::Base calls `establish_connection` (usually by an ancestor process that must have subsequently forked), `Octoshark.reset_connection_managers!` is automatically called to re-establish the Octoshark connections. It prevents `ActiveRecord::ConnectionNotEstablished` in the scenarios like:

* Unicorn before/after fork
* Spring prefork/serve
* Some rake tasks like `rake db:test:prepare`


## Database Cleaner

RSpec example on how to clean default and Octoshark data with Database Cleaner:

```ruby
config.before(:suite) do
  setup_database_cleaner
  DatabaseCleaner.clean_with(:truncation)
end

config.before(:each) do
  setup_database_cleaner
  DatabaseCleaner.start
end

config.after(:each) do
  setup_database_cleaner
  DatabaseCleaner.clean_with(:transaction)
end

def setup_database_cleaner
  DatabaseCleaner[:active_record, {connection: ActiveRecord::Base.connection_pool}]
  Octoshark.connection_managers.each do |manager|
    manager.connection_pools.each_pair do |connection_name, connection_pool|
      DatabaseCleaner[:active_record, {connection: connection_pool}]
    end
  end
end
```


## Logo

Thanks to [@saschamt](https://github.com/saschamt) for Octoshark logo design. :)


## Development Setup

Setup database config and create databases:

```bash
cp spec/support/config.yml.template spec/support/config.yml
rake db:create
```

Run specs:

```bash
bundle exec rspec spec
```

Install different active record versions defined in `Appraisals` and run specs for all of them:

```bash
bundle exec appraisal
bundle exec appraisal rspec spec
```


## Contributing

1. Fork it ( http://github.com/dalibor/octoshark/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
