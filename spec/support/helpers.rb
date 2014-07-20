module Helpers

  def check_connections_clean_up
    Octoshark.setup({})
    switcher = Octoshark.switcher

    Octoshark.with_connection(:default) { |connection| connection.execute("SELECT 1") }
    expect(switcher.connection_pools.map { |_, c| c.connections.count }.sum).to eq(1)

    yield

    expect(switcher.connection_pools.map { |_, c| c.connections.count }.sum).to eq(0)
  end

end
