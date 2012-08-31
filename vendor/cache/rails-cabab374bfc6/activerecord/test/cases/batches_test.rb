require 'cases/helper'
require 'models/post'

class EachTest < ActiveRecord::TestCase
  fixtures :posts

  def setup
    @posts = Post.order("id asc")
    @total = Post.count
    Post.count('id') # preheat arel's table cache
  end

  def test_each_should_excecute_one_query_per_batch
    assert_queries(Post.count + 1) do
      Post.find_each(:batch_size => 1) do |post|
        assert_kind_of Post, post
      end
    end
  end

  def test_each_should_not_return_query_chain_and_execcute_only_one_query
    assert_queries(1) do
      result = Post.find_each(:batch_size => 100000){ }
      assert_nil result
    end
  end

  def test_each_should_raise_if_select_is_set_without_id
    assert_raise(RuntimeError) do
      Post.find_each(:select => :title, :batch_size => 1) { |post| post }
    end
  end

  def test_each_should_execute_if_id_is_in_select
    assert_queries(6) do
      Post.find_each(:select => "id, title, type", :batch_size => 2) do |post|
        assert_kind_of Post, post
      end
    end
  end

  def test_each_should_raise_if_the_order_is_set
    assert_raise(RuntimeError) do
      Post.find_each(:order => "title") { |post| post }
    end
  end

  def test_each_should_raise_if_the_limit_is_set
    assert_raise(RuntimeError) do
      Post.find_each(:limit => 1) { |post| post }
    end
  end

  def test_warn_if_limit_scope_is_set
    ActiveRecord::Base.logger.expects(:warn)
    Post.limit(1).find_each { |post| post }
  end

  def test_warn_if_order_scope_is_set
    ActiveRecord::Base.logger.expects(:warn)
    Post.order("title").find_each { |post| post }
  end

  def test_find_in_batches_should_return_batches
    assert_queries(Post.count + 1) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

  def test_find_in_batches_should_start_from_the_start_option
    assert_queries(Post.count) do
      Post.find_in_batches(:batch_size => 1, :start => 2) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

  def test_find_in_batches_shouldnt_excute_query_unless_needed
    post_count = Post.count

    assert_queries(2) do
      Post.find_in_batches(:batch_size => post_count) {|batch| assert_kind_of Array, batch }
    end

    assert_queries(1) do
      Post.find_in_batches(:batch_size => post_count + 1) {|batch| assert_kind_of Array, batch }
    end
  end

  def test_find_in_batches_should_quote_batch_order
    c = Post.connection
    assert_sql(/ORDER BY #{c.quote_table_name('posts')}.#{c.quote_column_name('id')}/) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

  def test_find_in_batches_should_not_use_records_after_yielding_them_in_case_original_array_is_modified
    not_a_post = "not a post"
    not_a_post.stubs(:id).raises(StandardError, "not_a_post had #id called on it")

    assert_nothing_raised do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first

        batch.map! { not_a_post }
      end
    end
  end

  def test_find_in_batches_should_ignore_the_order_default_scope
    # First post is with title scope
    first_post = PostWithDefaultScope.first
    posts = []
    PostWithDefaultScope.find_in_batches  do |batch|
      posts.concat(batch)
    end
    # posts.first will be ordered using id only. Title order scope should not apply here
    assert_not_equal first_post, posts.first
    assert_equal posts(:welcome), posts.first
  end

  def test_find_in_batches_should_not_ignore_the_default_scope_if_it_is_other_then_order
    special_posts_ids = SpecialPostWithDefaultScope.all.map(&:id).sort
    posts = []
    SpecialPostWithDefaultScope.find_in_batches do |batch|
      posts.concat(batch)
    end
    assert_equal special_posts_ids, posts.map(&:id)
  end

end
