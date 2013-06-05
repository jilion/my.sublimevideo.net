require 'active_support/core_ext'

class SettingsFormatter

  attr_reader :hash

  def self.format(hash)
    new(hash).format
  end

  def initialize(hash)
    @hash = hash
  end

  def format
    hash_content = hash.map do |key, value|
      key = key.to_s.camelcase(:lower)
      if value.is_a?(Hash)
        [key, self.class.new(value).format]
      else
        [key, value]
      end
    end

    Hash[hash_content]
  end

end
