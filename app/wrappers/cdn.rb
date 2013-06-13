require 'edge_cast_wrapper'
require 'voxcast_wrapper'

module CDN
  WRAPPERS = [EdgeCastWrapper, VoxcastWrapper]

  # Works for file & directory
  def self.purge(path)
    wrappers.each do |wrapper|
      wrapper.delay.purge(path)
    end
  end

  def self.wrappers
    WRAPPERS
  end

end
