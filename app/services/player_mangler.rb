require 'multi_json'

class PlayerMangler

  def self.mangle(hash)
    new.mangle_hash(hash)
  end

  def self.mangle_key(key)
    new.mangle_key(key)
  end

  def mangle_hash(hash, parent_key = nil)
    Hash[hash.map { |key, value|
      key = key.to_s.camelcase(:lower)
      if value.is_a?(Hash)
        [mangle_key(key, parent_key), mangle_hash(value, key)]
      else
        [mangle_key(key, parent_key), value]
      end
    }]
  end

  def mangle_key(key, parent_key = nil)
    if parent_key && parent_key == 'kits'
      key.to_s
    else
      dictionary[key.to_s] || key.to_s
    end
  end

  private

  def dictionary
    $mangler_dictionary ||= begin
      json = File.read(Rails.root.join('config', 'mangler_dictionary.json'))
      MultiJson.load(json)
    end
  end

end
