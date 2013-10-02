class Hash

  # Allow to recursively loop on the hash values' values
  #
  #   h = { 'x' => { 'y' => 5 }, 'z' => 2 }
  #
  #   h.recursive_each_until_non_hash_values do |k, v|
  #     puts v
  #   end
  #   # => 5
  #   # => 2
  #
  def recursive_each_until_non_hash_values(&block)
    self.each do |k, v|
      if v.respond_to?(:each)
        v.send(__method__, &block)
      else
        yield(k, v)
      end
    end
  end

end
