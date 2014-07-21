![Travis status](https://travis-ci.org/dalibor/octoshark.png)

# Octoshark

Octoshark is a simple ActiveRecord connection switcher. It provides a general purpose connection switching mechanism that can be used in sharding and master-slave multi-database environments. It's up to you to specify how ActiveRecord models will use the Octoshark connections, see below for example scenarios.


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

Specify the connections for Octoshark to manage. This is usually done in an app initializer.

```ruby
Octoshark.configure({
  db1: { adapter: "sqlite3", database: "db/db1.sqlite" },
  db2: { adapter: "sqlite3", database: "db/db2.sqlite" }
})
```

Configure which ActiveRecord models will use the Octoshark connection by overriding the Model.connection method. If there are many models, extract it in a module and include it.

```ruby
class Post < ActiveRecord::Base
  def self.connection
    Octoshark.current_connection
  end
end
```

To use a specific database connection, do:

```ruby
Octoshark.with_connection(:db1) do
  # work with db1
  Post.first
end
```

Octoshark connection is changed for the duration of the block and then reversed back to the previous connection.

`Octoshark.current_connection` returns the active connection while in `with_connection` block, and outside it raises `Octoshark::NoCurrentConnectionError` error.

Multiple connection switch blocks can be nested:

```ruby
Octoshark.with_connection(:db1) do
  # work with db1

  Octoshark.with_connection(:db2) do
    # work with db2
  end

  # work with db1
end
```


## Sharding Example

For example, let's say we have few models that are in the default Rails database (User, Account, etc) and few models that we want to shard (Blog, Post, Comment, etc). For all models in the default database, we can use the default ActiveRecord connection, and for all sharded models we need to the Octoshark connection.

We specify the connection for the sharded models based on the shard key (User) in a controller with an around filter:

```ruby
# before_filter :find_user
around_filter :select_shard

def select_shard(&block)
  Octoshark.with_connection(current_user.shard, &block)
end
```

Similarly, in all other application entry-points that start with the default ActiveRecord connection (background jobs for an example), we need to switch the shard connection and then proceed.


## Master-Slave Example

When we want to do something in the slave database with all ActiveRecord models, then we need to add Octoshark's current or default connection to all models, either by overriding `ActiveRecord:Base.connection` or using a module that we include in all models.

```ruby
class ActiveRecord::Base
  def self.connection
    # Some rake tasks like `rake db:create` does not load initializers,
    # and because we're overriding ActiveRecord::Base.connection,
    # we need to make sure Octoshark is configured before using it.
    Octoshark.configure(configs) unless Octoshark.configured?

    # Return the current connection (from with_connection block) or default one
    Octoshark.current_or_default_connection
  end
end
```

Here we use `Octoshark.current_or_default_connection` method which returns the current connection while in `with_connection` block and fallback to the default connection when outside.


## Octoshark.reload!

Whenever ActiveRecord::Base establishes a new database connection, `Octoshark.reload!` is called. This is necessary for Octoshark to disconnect old connection pools and set new ones, otherwise `ActiveRecord::ConnectionNotEstablished` will be raised.

Few examples where database connections are re-established:

* Unicorn before/after fork
* Spring prefork/serve
* Some rake tasks like `rake db:test:prepare`


## Database Cleaner

Here's an example how to clean default and shard databases using both default connection and Octoshark connections:

```ruby
config.before(:suite) do
  clean_database_with(:truncation)
end

config.before(:each) do
  DatabaseCleaner.start
end

config.after(:each) do
  clean_database_with(:transaction)
end

def clean_database_with
  # default ActiveRecord::Base connection pool
  DatabaseCleaner[:active_record, {connection: ActiveRecord::Base.connection_pool}]

  # Octoshark connection pool for the connection
  Octoshark.connection_pools.each_pair do |name, connection_pool|
    DatabaseCleaner[:active_record, {connection: connection_pool}]
  end

  DatabaseCleaner.clean_with(strategy)
end
```

## Contributing

1. Fork it ( http://github.com/dalibor/octoshark/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
