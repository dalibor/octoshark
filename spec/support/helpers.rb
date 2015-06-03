module Helpers

  def configs
    {
      db1: { adapter: "sqlite3", database: "tmp/db1.sqlite" },
      db2: { adapter: "sqlite3", database: "tmp/db2.sqlite" }
    }
  end

  def db(connection)
    connection.execute('PRAGMA database_list').
      first['file'].
      split('/').last.
      split('.').first
  end

  def check_connections_clean_up(manager, connection_name)
    manager.with_connection(connection_name) { |connection| connection.execute("SELECT 1") }
    expect(manager.connection_pools.map { |_, c| c.connections.count }.sum).to eq(1)

    yield

    expect(manager.connection_pools.map { |_, c| c.connections.count }.sum).to eq(0)
  end
end
