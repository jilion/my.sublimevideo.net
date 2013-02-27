class Hash

  # Returns a new hash with sub keys joins to one level.
  #
  #   h = { 'x' => { 'y' => 5 }, 'z' => 2 }
  #
  #   h.join_keys #=> { 'x.y' => 5, 'z' => 2 }
  def join_keys
    self.inject(self.class.new(0)) { |hash, attrs|
      join_key(hash, *attrs)
    }
  end

  private

  def join_key(hash, key, value)
    if value.is_a?(Hash)
      value.each { |k, v| join_key(hash, "#{key}.#{k}", v) }
    else
      hash[key.to_s] = value
    end
    hash
  end

end
