require 'cases/helper'
require 'tempfile'

module ActiveRecord
  class Fixtures
    class FileTest < ActiveRecord::TestCase
      def test_open
        fh = File.open(::File.join(FIXTURES_ROOT, "accounts.yml"))
        assert_equal 6, fh.to_a.length
      end

      def test_open_with_block
        called = false
        File.open(::File.join(FIXTURES_ROOT, "accounts.yml")) do |fh|
          called = true
          assert_equal 6, fh.to_a.length
        end
        assert called, 'block called'
      end

      def test_names
        File.open(::File.join(FIXTURES_ROOT, "accounts.yml")) do |fh|
          assert_equal ["signals37",
                        "unknown",
                        "rails_core_account",
                        "last_account",
                        "rails_core_account_2",
                        "odegy_account"].sort, fh.to_a.map(&:first).sort
        end
      end

      def test_values
        File.open(::File.join(FIXTURES_ROOT, "accounts.yml")) do |fh|
          assert_equal [1,2,3,4,5,6].sort, fh.to_a.map(&:last).map { |x|
            x['id']
          }.sort
        end
      end

      def test_erb_processing
        File.open(::File.join(FIXTURES_ROOT, "developers.yml")) do |fh|
          devs = Array.new(8) { |i| "dev_#{i + 3}" }
          assert_equal [], devs - fh.to_a.map(&:first)
        end
      end

      def test_empty_file
        tmp_yaml ['empty', 'yml'], '' do |t|
          assert_equal [], File.open(t.path) { |fh| fh.to_a }
        end
      end

      # A valid YAML file is not necessarily a value Fixture file. Make sure
      # an exception is raised if the format is not valid Fixture format.
      def test_wrong_fixture_format_string
        tmp_yaml ['empty', 'yml'], 'qwerty' do |t|
          assert_raises(ActiveRecord::Fixture::FormatError) do
            File.open(t.path) { |fh| fh.to_a }
          end
        end
      end

      def test_wrong_fixture_format_nested
        tmp_yaml ['empty', 'yml'], 'one: two' do |t|
          assert_raises(ActiveRecord::Fixture::FormatError) do
            File.open(t.path) { |fh| fh.to_a }
          end
        end
      end

      private
      def tmp_yaml(name, contents)
        t = Tempfile.new name
        t.binmode
        t.write contents
        t.close
        yield t
      ensure
        t.close true
      end
    end
  end
end
