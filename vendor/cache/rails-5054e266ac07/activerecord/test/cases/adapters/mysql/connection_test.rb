require "cases/helper"

class MysqlConnectionTest < ActiveRecord::TestCase
  def setup
    super
    @connection = ActiveRecord::Base.connection
  end

  def test_mysql_reconnect_attribute_after_connection_with_reconnect_true
    run_without_connection do |orig_connection|
      ActiveRecord::Base.establish_connection(orig_connection.merge({:reconnect => true}))
      assert ActiveRecord::Base.connection.raw_connection.reconnect
    end
  end

  def test_connect_with_url
    run_without_connection do |orig|
      ar_config = ARTest.connection_config['arunit']
      url = "mysql://#{ar_config["username"]}@localhost/#{ar_config["database"]}"
      klass = Class.new(ActiveRecord::Base)
      klass.establish_connection(url)
      assert_equal ar_config['database'], klass.connection.current_database
    end
  end

  def test_mysql_reconnect_attribute_after_connection_with_reconnect_false
    run_without_connection do |orig_connection|
      ActiveRecord::Base.establish_connection(orig_connection.merge({:reconnect => false}))
      assert !ActiveRecord::Base.connection.raw_connection.reconnect
    end
  end

  def test_no_automatic_reconnection_after_timeout
    assert @connection.active?
    @connection.update('set @@wait_timeout=1')
    sleep 2
    assert !@connection.active?
  end

  def test_successful_reconnection_after_timeout_with_manual_reconnect
    assert @connection.active?
    @connection.update('set @@wait_timeout=1')
    sleep 2
    @connection.reconnect!
    assert @connection.active?
  end

  def test_successful_reconnection_after_timeout_with_verify
    assert @connection.active?
    @connection.update('set @@wait_timeout=1')
    sleep 2
    @connection.verify!
    assert @connection.active?
  end

  def test_bind_value_substitute
    bind_param = @connection.substitute_at('foo', 0)
    assert_equal Arel.sql('?'), bind_param
  end

  def test_exec_no_binds
    @connection.exec_query('drop table if exists ex')
    @connection.exec_query(<<-eosql)
      CREATE TABLE `ex` (`id` int(11) DEFAULT NULL auto_increment PRIMARY KEY,
        `data` varchar(255))
    eosql
    result = @connection.exec_query('SELECT id, data FROM ex')
    assert_equal 0, result.rows.length
    assert_equal 2, result.columns.length
    assert_equal %w{ id data }, result.columns

    @connection.exec_query('INSERT INTO ex (id, data) VALUES (1, "foo")')

    # if there are no bind parameters, it will return a string (due to
    # the libmysql api)
    result = @connection.exec_query('SELECT id, data FROM ex')
    assert_equal 1, result.rows.length
    assert_equal 2, result.columns.length

    assert_equal [['1', 'foo']], result.rows
  end

  def test_exec_with_binds
    @connection.exec_query('drop table if exists ex')
    @connection.exec_query(<<-eosql)
      CREATE TABLE `ex` (`id` int(11) DEFAULT NULL auto_increment PRIMARY KEY,
        `data` varchar(255))
    eosql
    @connection.exec_query('INSERT INTO ex (id, data) VALUES (1, "foo")')
    result = @connection.exec_query(
      'SELECT id, data FROM ex WHERE id = ?', nil, [[nil, 1]])

    assert_equal 1, result.rows.length
    assert_equal 2, result.columns.length

    assert_equal [[1, 'foo']], result.rows
  end

  def test_exec_typecasts_bind_vals
    @connection.exec_query('drop table if exists ex')
    @connection.exec_query(<<-eosql)
      CREATE TABLE `ex` (`id` int(11) DEFAULT NULL auto_increment PRIMARY KEY,
        `data` varchar(255))
    eosql
    @connection.exec_query('INSERT INTO ex (id, data) VALUES (1, "foo")')
    column = @connection.columns('ex').find { |col| col.name == 'id' }

    result = @connection.exec_query(
      'SELECT id, data FROM ex WHERE id = ?', nil, [[column, '1-fuu']])

    assert_equal 1, result.rows.length
    assert_equal 2, result.columns.length

    assert_equal [[1, 'foo']], result.rows
  end

  # Test that MySQL allows multiple results for stored procedures
  if defined?(Mysql) && Mysql.const_defined?(:CLIENT_MULTI_RESULTS)
    def test_multi_results
      rows = ActiveRecord::Base.connection.select_rows('CALL ten();')
      assert_equal 10, rows[0][0].to_i, "ten() did not return 10 as expected: #{rows.inspect}"
      assert @connection.active?, "Bad connection use by 'MysqlAdapter.select_rows'"
    end
  end

  private

  def run_without_connection
    original_connection = ActiveRecord::Base.remove_connection
    begin
      yield original_connection
    ensure
      ActiveRecord::Base.establish_connection(original_connection)
    end
  end
end
