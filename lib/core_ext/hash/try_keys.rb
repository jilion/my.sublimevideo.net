require 'active_support/core_ext/object/try'

class Hash

  # Returns a new hash with sub keys joins to one level.
  #
  #   h = { 'x' => { 'y' => 5 } }
  #
  #   h.try_keys('x', 'y') #=> 5
  #   h.try_keys('x', 'z') #=> nil
  #   h.try_keys('x', 'z') { 42 } #=> 42
  #
  def try_keys(*keys, &block)
    value = self.try(:[], keys.shift)

    if !keys.empty? && value.respond_to?(:try_keys)
      value.try_keys(*keys, &block)
    else
      value || block.try(:call)
    end
  end

end
