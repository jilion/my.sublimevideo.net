require "cases/helper"
require 'models/topic'

module ActiveRecord
  class DupTest < ActiveRecord::TestCase
    fixtures :topics

    def test_dup
      assert !Topic.new.freeze.dup.frozen?
    end

    def test_not_readonly
      topic = Topic.order(:id).first

      duped = topic.dup
      assert !duped.readonly?, 'should not be readonly'
    end

    def test_is_readonly
      topic = Topic.order(:id).first
      topic.readonly!

      duped = topic.dup
      assert duped.readonly?, 'should be readonly'
    end

    def test_dup_not_persisted
      topic = Topic.order(:id).first
      duped = topic.dup

      assert !duped.persisted?, 'topic not persisted'
      assert duped.new_record?, 'topic is new'
    end

    def test_dup_has_no_id
      topic = Topic.order(:id).first
      duped = topic.dup
      assert_nil duped.id
    end

    def test_dup_with_modified_attributes
      topic = Topic.order(:id).first
      topic.author_name = 'Aaron'
      duped = topic.dup
      assert_equal 'Aaron', duped.author_name
    end

    def test_dup_with_changes
      dbtopic = Topic.order(:id).first
      topic = Topic.new

      topic.attributes = dbtopic.attributes

      #duped has no timestamp values
      duped = dbtopic.dup

      #clear topic timestamp values
      topic.send(:clear_timestamp_attributes)

      assert_equal topic.changes, duped.changes
    end

    def test_dup_topics_are_independent
      topic = Topic.order(:id).first
      topic.author_name = 'Aaron'
      duped = topic.dup

      duped.author_name = 'meow'

      assert_not_equal topic.changes, duped.changes
    end

    def test_dup_attributes_are_independent
      topic = Topic.order(:id).first
      duped = topic.dup

      duped.author_name = 'meow'
      topic.author_name = 'Aaron'

      assert_equal 'Aaron', topic.author_name
      assert_equal 'meow', duped.author_name
    end

    def test_dup_timestamps_are_cleared
      topic = Topic.order(:id).first
      assert_not_nil topic.updated_at
      assert_not_nil topic.created_at

      # temporary change to the topic object
      topic.updated_at -= 3.days

      #dup should not preserve the timestamps if present
      new_topic = topic.dup
      assert_nil new_topic.updated_at
      assert_nil new_topic.created_at

      new_topic.save
      assert_not_nil new_topic.updated_at
      assert_not_nil new_topic.created_at
    end
  end
end
