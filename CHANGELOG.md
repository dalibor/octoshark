# Change log

## 0.5.1 2024-04-22

- Add kwargs argument to the ActiveRecordAbstractAdapter

## 0.5.0 2023-10-27

- Add support for Rails 7.1
- Drop legacy test job because ubuntu-18.04 build node is not available anymore

## 0.4.0 2022-02-12

- Add support for Rails 7.0
- Fix `establish_connection` for Ruby 3

## 0.3.0 2021-07-20

- Add support for Rails 6.1

## 0.2.2 2016-11-09

- Fix `alias_method_chain` deprecation in Rails 5

## 0.2.1 2016-09-09

- Add support for Rails 5 and Rails 3

## 0.2.0 2016-08-29

- `Octoshark::ConnectionManager` is split in two managers `Octoshark::ConnectionPoolsManager` for persistent connections and `Octoshark::ConnectionManager` for non-persistent connections.
- `Octoshark` class methods like `connection_managers`, `reset_connection_managers!`, `disconnect!` are only relevant and moved to `Octoshark::ConnectionPoolsManager` class.
- `Octoshark::ConnectionManager#use_database` method has been removed and the functionality moved to `Octoshark::ConnectionPoolsManager#with_connection(name, database_name)` where the second optional argument `database_name` when specified will switch the connection to the database using the `use database` MySQL statement.
