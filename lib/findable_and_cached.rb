module FindableAndCached
  extend ActiveSupport::Concern

  included do
    class << self
      alias_method :get, :find_cached_by_name
    end
  end

  module ClassMethods
    def find_cached_by_name(name)
      Rails.cache.fetch [self, 'find_cached_by_name', name.to_s.dup] do
        where(name: name.to_s).first
      end
    end
  end

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_name', name]
  end

end
