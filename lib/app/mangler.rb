require 'multi_json'

class App::Mangler

  def self.mangle(hash)
    new(hash).mangle
  end

  def initialize(hash)
    @hash = hash
  end

  def mangle
    mangle_hash(@hash)
  end

private

  def mangle_hash(hash)
    Hash[hash.map { |key, value|
      if value.is_a?(Hash)
        [mangle_key(key), mangle_hash(value)]
      else
        [mangle_key(key), value]
      end
    }]
  end

  def mangle_key(key)
    dictionary[key.to_s] || key.to_s
  end

  def dictionary
    $mangler_dictionary ||= begin
      json = File.read(Rails.root.join('config', 'mangler_dictionary.json'))
      MultiJson.load(json)
    end
  end

end
