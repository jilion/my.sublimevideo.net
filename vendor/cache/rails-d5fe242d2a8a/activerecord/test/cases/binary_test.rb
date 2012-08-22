# encoding: utf-8
require "cases/helper"

# Without using prepared statements, it makes no sense to test
# BLOB data with DB2 or Firebird, because the length of a statement
# is limited to 32KB.
unless current_adapter?(:SybaseAdapter, :DB2Adapter, :FirebirdAdapter)
  require 'models/binary'

  class BinaryTest < ActiveRecord::TestCase
    FIXTURES = %w(flowers.jpg example.log test.txt)

    def test_mixed_encoding
      str = "\x80"
      str.force_encoding('ASCII-8BIT') if str.respond_to?(:force_encoding)

      binary = Binary.new :name => 'いただきます！', :data => str
      binary.save!
      binary.reload
      assert_equal str, binary.data

      name = binary.name

      # Mysql adapter doesn't properly encode things, so we have to do it
      if current_adapter?(:MysqlAdapter)
        name.force_encoding('UTF-8') if name.respond_to?(:force_encoding)
      end
      assert_equal 'いただきます！', name
    end

    def test_load_save
      Binary.delete_all

      FIXTURES.each do |filename|
        data = File.read(ASSETS_ROOT + "/#{filename}")
        data.force_encoding('ASCII-8BIT') if data.respond_to?(:force_encoding)
        data.freeze

        bin = Binary.new(:data => data)
        assert_equal data, bin.data, 'Newly assigned data differs from original'

        bin.save!
        assert_equal data, bin.data, 'Data differs from original after save'

        assert_equal data, bin.reload.data, 'Reloaded data differs from original'
      end
    end
  end
end
