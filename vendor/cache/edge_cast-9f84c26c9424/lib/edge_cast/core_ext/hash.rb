require 'edge_cast/core_ext/string'

class Hash

  def symbolize_keys!
    self.keys.each do |key|
      value = delete(key)
      self[key.to_sym] = value.respond_to?(:symbolize_keys!) ? value.symbolize_keys! : value
    end
    self
  end

  def to_result!
    keys.each do |key|
      value = delete(key)
      self[key.to_s.underscore.to_sym] = value.respond_to?(:to_result!) ? value.to_result! : value
    end
    self
  end

  def to_api!
    keys.each do |key|
      value = delete(key)
      self[key.to_s.camelize] = value.respond_to?(:to_api!) ? value.to_api! : value
    end
    self
  end

end
