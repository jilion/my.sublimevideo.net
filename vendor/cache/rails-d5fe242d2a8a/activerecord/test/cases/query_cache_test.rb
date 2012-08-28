require "cases/helper"
require 'models/topic'
require 'models/task'
require 'models/category'
require 'models/post'


class QueryCacheTest < ActiveRecord::TestCase
  fixtures :tasks, :topics, :categories, :posts, :categories_posts

  def setup
    Task.connection.clear_query_cache
    ActiveRecord::Base.connection.disable_query_cache!
  end

  def test_exceptional_middleware_clears_and_disables_cache_on_error
    assert !ActiveRecord::Base.connection.query_cache_enabled, 'cache off'

    mw = ActiveRecord::QueryCache.new lambda { |env|
      Task.find 1
      Task.find 1
      assert_equal 1, ActiveRecord::Base.connection.query_cache.length
      raise "lol borked"
    }
    assert_raises(RuntimeError) { mw.call({}) }

    assert_equal 0, ActiveRecord::Base.connection.query_cache.length
    assert !ActiveRecord::Base.connection.query_cache_enabled, 'cache off'
  end

  def test_exceptional_middleware_leaves_enabled_cache_alone
    ActiveRecord::Base.connection.enable_query_cache!

    mw = ActiveRecord::QueryCache.new lambda { |env|
      raise "lol borked"
    }
    assert_raises(RuntimeError) { mw.call({}) }

    assert ActiveRecord::Base.connection.query_cache_enabled, 'cache on'
  end

  def test_middleware_delegates
    called = false
    mw = ActiveRecord::QueryCache.new lambda { |env|
      called = true
    }
    mw.call({})
    assert called, 'middleware should delegate'
  end

  def test_middleware_caches
    mw = ActiveRecord::QueryCache.new lambda { |env|
      Task.find 1
      Task.find 1
      assert_equal 1, ActiveRecord::Base.connection.query_cache.length
    }
    mw.call({})
  end

  def test_cache_enabled_during_call
    assert !ActiveRecord::Base.connection.query_cache_enabled, 'cache off'

    mw = ActiveRecord::QueryCache.new lambda { |env|
      assert ActiveRecord::Base.connection.query_cache_enabled, 'cache on'
    }
    mw.call({})
  end

  def test_cache_on_during_body_write
    streaming = Class.new do
      def each
        yield ActiveRecord::Base.connection.query_cache_enabled
      end
    end

    mw = ActiveRecord::QueryCache.new lambda { |env|
      [200, {}, streaming.new]
    }
    body = mw.call({}).last
    body.each { |x| assert x, 'cache should be on' }
    body.close
    assert !ActiveRecord::Base.connection.query_cache_enabled, 'cache disabled'
  end

  def test_cache_off_after_close
    mw = ActiveRecord::QueryCache.new lambda { |env| }
    body = mw.call({}).last

    assert ActiveRecord::Base.connection.query_cache_enabled, 'cache enabled'
    body.close
    assert !ActiveRecord::Base.connection.query_cache_enabled, 'cache disabled'
  end

  def test_cache_clear_after_close
    mw = ActiveRecord::QueryCache.new lambda { |env|
      Post.find(:first)
    }
    body = mw.call({}).last

    assert !ActiveRecord::Base.connection.query_cache.empty?, 'cache not empty'
    body.close
    assert ActiveRecord::Base.connection.query_cache.empty?, 'cache should be empty'
  end

  def test_find_queries
    assert_queries(ActiveRecord::IdentityMap.enabled? ? 1 : 2) { Task.find(1); Task.find(1) }
  end

  def test_find_queries_with_cache
    Task.cache do
      assert_queries(1) { Task.find(1); Task.find(1) }
    end
  end

  def test_find_queries_with_cache_multi_record
    Task.cache do
      assert_queries(2) { Task.find(1); Task.find(1); Task.find(2) }
    end
  end

  def test_count_queries_with_cache
    Task.cache do
      assert_queries(1) { Task.count; Task.count }
    end
  end

  def test_query_cache_dups_results_correctly
    Task.cache do
      now  = Time.now.utc
      task = Task.find 1
      assert_not_equal now, task.starting
      task.starting = now
      task.reload
      assert_not_equal now, task.starting
    end
  end

  def test_cache_is_flat
    Task.cache do
      Topic.columns # don't count this query
      assert_queries(1) { Topic.find(1); Topic.find(1); }
    end

    ActiveRecord::Base.cache do
      assert_queries(1) { Task.find(1); Task.find(1) }
    end
  end

  def test_cache_does_not_wrap_string_results_in_arrays
    if current_adapter?(:SQLite3Adapter)
      require 'sqlite3/version'
      sqlite3_version = RUBY_PLATFORM =~ /java/ ? Jdbc::SQLite3::VERSION : SQLite3::VERSION
    end

    Task.cache do
      # Oracle adapter returns count() as Fixnum or Float
      if current_adapter?(:OracleAdapter)
        assert_kind_of Numeric, Task.connection.select_value("SELECT count(*) AS count_all FROM tasks")
      elsif current_adapter?(:SQLite3Adapter) && sqlite3_version > '1.2.5' || current_adapter?(:Mysql2Adapter)
        # Future versions of the sqlite3 adapter will return numeric
        assert_instance_of Fixnum,
         Task.connection.select_value("SELECT count(*) AS count_all FROM tasks")
      else
        assert_instance_of String, Task.connection.select_value("SELECT count(*) AS count_all FROM tasks")
      end
    end
  end

  def test_cache_is_ignored_for_locked_relations
    task = Task.find 1

    Task.cache do
      assert_queries(2) { task.lock!; task.lock! }
    end
  end
end

class QueryCacheExpiryTest < ActiveRecord::TestCase
  fixtures :tasks, :posts, :categories, :categories_posts

  def test_cache_gets_cleared_after_migration
    # warm the cache
    Post.find(1)

    # change the column definition
    Post.connection.change_column :posts, :title, :string, :limit => 80
    assert_nothing_raised { Post.find(1) }

    # restore the old definition
    Post.connection.change_column :posts, :title, :string
  end

  def test_find
    Task.connection.expects(:clear_query_cache).times(1)

    assert !Task.connection.query_cache_enabled
    Task.cache do
      assert Task.connection.query_cache_enabled
      Task.find(1)

      Task.uncached do
        assert !Task.connection.query_cache_enabled
        Task.find(1)
      end

      assert Task.connection.query_cache_enabled
    end
    assert !Task.connection.query_cache_enabled
  end

  def test_update
    Task.connection.expects(:clear_query_cache).times(2)

    Task.cache do
      task = Task.find(1)
      task.starting = Time.now.utc
      task.save!
    end
  end

  def test_destroy
    Task.connection.expects(:clear_query_cache).times(2)

    Task.cache do
      Task.find(1).destroy
    end
  end

  def test_insert
    ActiveRecord::Base.connection.expects(:clear_query_cache).times(2)

    Task.cache do
      Task.create!
    end
  end

  def test_cache_is_expired_by_habtm_update
    ActiveRecord::Base.connection.expects(:clear_query_cache).times(2)
    ActiveRecord::Base.cache do
      c = Category.find(:first)
      p = Post.find(:first)
      p.categories << c
    end
  end

  def test_cache_is_expired_by_habtm_delete
    ActiveRecord::Base.connection.expects(:clear_query_cache).times(2)
    ActiveRecord::Base.cache do
      p = Post.find(1)
      assert p.categories.any?
      p.categories.delete_all
    end
  end
end

class QueryCacheBodyProxyTest < ActiveRecord::TestCase

  test "is polite to it's body and responds to it" do
    body = Class.new(String) { def to_path; "/path"; end }.new
    proxy = ActiveRecord::QueryCache::BodyProxy.new(nil, body, ActiveRecord::Base.connection_id)
    assert proxy.respond_to?(:to_path)
    assert_equal proxy.to_path, "/path"
  end

end
