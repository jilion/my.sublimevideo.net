require "cases/helper"
require 'models/topic'

module ActiveRecord
  module ConnectionAdapters
    class Mysql2Adapter
      class BindParameterTest < ActiveRecord::TestCase
        fixtures :topics

        def test_update_question_marks
          str       = "foo?bar"
          x         = Topic.find :first
          x.title   = str
          x.content = str
          x.save!
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_create_question_marks
          str = "foo?bar"
          x   = Topic.create!(:title => str, :content => str)
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_update_null_bytes
          str       = "foo\0bar"
          x         = Topic.find :first
          x.title   = str
          x.content = str
          x.save!
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_create_null_bytes
          str = "foo\0bar"
          x   = Topic.create!(:title => str, :content => str)
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end
      end
    end
  end
end
