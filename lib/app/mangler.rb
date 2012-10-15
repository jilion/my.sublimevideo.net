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

  def mangle_hash(hash, parent_key = nil)
    Hash[hash.map { |key, value|
      if value.is_a?(Hash)
        [mangle_key(key, parent_key), mangle_hash(value, key)]
      else
        [mangle_key(key, parent_key), value]
      end
    }]
  end

  def mangle_key(key, parent_key)
    if parent_key && parent_key == 'kits'
      key.to_s
    else
      dictionary[key.to_s] || key.to_s
    end
  end

  def dictionary
    $mangler_dictionary ||= begin
      json = File.read(Rails.root.join('config', 'mangler_dictionary.json'))
      MultiJson.load(json)
    end
  end

end
