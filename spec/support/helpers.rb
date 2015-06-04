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
end
