class Hash

  # Returns a new hash with sub keys joins to one level.
  #
  #   h = { 'x' => { 'y' => 5 }, 'z' => 2 }
  #
  #   h.join_keys #=> { 'x.y' => 5, 'z' => 2 }
  def join_keys(separator = '.')
    self.reduce(self.class.new(0)) { |hash, (k, v)| join_key(hash, k, v, separator) }
  end

  private

  def join_key(hash, key, value, separator)
    if value.is_a?(Hash)
      value.each { |k, v| join_key(hash, "#{key}#{separator}#{k}", v, separator) }
    else
      hash[key.to_s] = value
    end
    hash
  end

end
