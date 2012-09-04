module ActiveRecord
  class Base
    def self.fake_connection(config)
      ConnectionAdapters::FakeAdapter.new nil, logger
    end
  end

  module ConnectionAdapters
    class FakeAdapter < AbstractAdapter
      attr_accessor :tables, :primary_keys

      @columns = Hash.new { |h,k| h[k] = [] }
      class << self
        attr_reader :columns
      end

      def initialize(connection, logger)
        super
        @tables       = []
        @primary_keys = {}
        @columns      = self.class.columns
      end

      def primary_key(table)
        @primary_keys[table]
      end

      def merge_column(table_name, name, sql_type = nil, options = {})
        @columns[table_name] << ActiveRecord::ConnectionAdapters::Column.new(
          name.to_s,
          options[:default],
          sql_type.to_s,
          options[:null])
      end

      def columns(table_name, message)
        @columns[table_name]
      end
    end
  end
end
