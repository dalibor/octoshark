![Octoshark logo](https://dl.dropboxusercontent.com/u/3230730/github/octoshark.png)

![Travis status](https://travis-ci.org/dalibor/octoshark.png)

Octoshark is a simple ActiveRecord connection manager. It provides connection switching mechanisms that can be used in various scenarios like master-slave, sharding or multi-tenant architecture.


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

Octoshark has two connection managers: `ConnectionPoolsManager` for managing connection pools using persistent connections and `ConnectionManager` for managing non-persistent connections. It depends on your application performance and scaling requirements which one to use.

- If you have a limited number of consumers (application and worker servers), `ConnectionPoolsManager` would be the preferred option. Standard Rails application has a single connection pool, and `ConnectionPoolsManager` just makes it possible for application models to work with multiple connection pools.

- If you have a very big infrastructure with lots of consumers (application and worker servers) and you are hitting max connections limit on database servers, i.e. you need to scale horizontally, `ConnectionManager` is the option to use. Because it uses non-persistent connections it comes up with a performance penalty because connections are re-established over and over again. Some ActiveRecord plugins that depend on having an active database connection all the time might need a change in order to work with non-persistent connections.

`ConnectionPoolsManager` and `ConnectionManager` can be combined together and many of them can be used at the same time.

Here is how to create connection pools manager:

```ruby
CONN_MANAGER = Octoshark::ConnectionPoolsManager.new({ c1: config1, c2: config2 })
```

`config1` and `config2` are standard ActiveRecord database configs:

```ruby
config = {
  adapter:  'mysql2',
  host:     'localhost',
  port:     3306,
  database: 'database',
  username: 'root',
  password: 'pass',
  pool:     1,
  encoding: 'utf8',
  reconnect: false
}
```

To switch a connection using a specific pool:

```ruby
CONN_MANAGER.with_connection(:c1) do |connection|
  connection.execute("SELECT 1")
end
```

Multiple `with_connection` blocks can be nested:

```ruby
CONN_MANAGER.with_connection(config1) do
  # run queries on connection specified with config1

  CONN_MANAGER.with_connection(config2) do
    # run queries on connection specified with config2
  end

  # run queries on connection specified with config1
end
```

If you establish a connection to database server instead of to database, then you can use the second optional argument `database_name` to tell the connection manager to switch the connection to that database within the same connection. This is useful when you want to have fewer connection pools and keep number of active connection per database server under control. This option is only MySQL specific for now, it uses `USE database_name` statement to switch the connection.

```ruby
CONN_MANAGER.with_connection(:c1, database_name) do |connection|
  connection.execute("SELECT 1")
end
```

Using non-persistent connections with `Octoshark::ConnectionManager` has the same API:


```ruby
CONN_MANAGER = Octoshark::ConnectionManager.new
```

Opening a new connection, executing query and closing the connection:

```ruby
CONN_MANAGER.with_connection(config) do |connection|
  connection.execute("SELECT 1")
end
```


## Using Octoshark with ActiveRecord models

To tell an ActiveRecord model to use the Octoshark connection we can override the `Model.connection` method.

```ruby
class Post < ActiveRecord::Base
  def self.connection
    CONN_MANAGER.current_connection
  end
end
```

Alternatively, we can extract it as a module and include in multiple models.

```ruby
module ShardingModel
  extend ActiveSupport::Concern

  module ClassMethods
    def connection
      CONN_MANAGER.current_connection
    end
  end
end
```

To use a specific database connection:

```ruby
CONN_MANAGER.with_connection(:c1) do
  # run queries on c1
  Post.first
end
```

This connection switching in Rails applications is usually done from within an `around_filter` for controllers and in a similar way for other application "entry-points" like background jobs:

```ruby
around_filter :select_shard

def select_shard(&block)
  CONN_MANAGER.with_connection(current_user.shard, &block)
end
```

`CONN_MANAGER.current_connection` returns the active connection while the execution is in the `with_connection` block or raises `Octoshark::Error::NoCurrentConnection` outside of the `with_connection` block. In some cases, falling back to the default database connection for the Rails app might be preferable which can be done using `CONN_MANAGER.current_or_default_connection`.


## Octoshark::ConnectionPoolsManager.reset_connection_managers!

When using `Octoshark::ConnectionPoolsManager`, whenever ActiveRecord::Base calls `establish_connection` (usually by an ancestor process that must have subsequently forked), `Octoshark.reset_connection_managers!` is automatically called to re-establish the Octoshark connections. It prevents `ActiveRecord::ConnectionNotEstablished` in the scenarios like:

* Unicorn before/after fork
* Spring prefork/serve
* Some rake tasks like `rake db:test:prepare`


## Cleaning test databases

When using persistent connections, you can use tools like [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner) or [DatabaseRewinder](https://github.com/amatsuda/database_rewinder) to clean test databases. Here's an example of RSpec config for `DatabaseCleaner`:

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
  Octoshark::ConnectionPoolsManager.connection_managers.each do |manager|
    manager.connection_pools.each_pair do |connection_name, connection_pool|
      DatabaseCleaner[:active_record, {connection: connection_pool}]
    end
  end
end
```

When using non-persistent connections where transaction rollback as a cleaning strategy will not work, we can use a custom solution inspired by `DatabaseRewinder`. It also works with dynamic databases created on the fly in the test suite.

```ruby
module DatabaseCleaner
  module InsertRecorder
    def execute(sql, *)
      DatabaseCleaner.record_inserted_table(self, sql)
      super
    end

    def exec_query(sql, *)
      DatabaseCleaner.record_inserted_table(self, sql)
      super
    end
  end

  @@tables = []

  def self.tables
    @@tables
  end

  def self.record_inserted_table(connection, sql)
    match = sql.match(/\AINSERT(?:\s+IGNORE)?\s+INTO\s+(?:\.*[`"]?([^.\s`"]+)[`"]?)*/i)
    tables << match[1] if match && !tables.include?(match[1])
  end

  def self.clean
    CoreDB.with_connection do |connection|
      (
        connection.tables.reject { |t| t == ActiveRecord::Migrator.schema_migrations_table_name } & tables
      ).each do |table|
        connection.disable_referential_integrity do
          connection.execute "DELETE FROM #{connection.quote_table_name(table)};"
        end
      end
    end
    @@tables = []
  end
end

require 'active_record/connection_adapters/abstract_mysql_adapter'
ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.send(:prepend, DatabaseCleaner::InsertRecorder)
```


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


## Logo

Thanks to [@saschamt](https://github.com/saschamt) for Octoshark logo design. :)


## Contributing

1. Fork it ( http://github.com/dalibor/octoshark/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
