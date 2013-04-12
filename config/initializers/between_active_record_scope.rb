module ActiveRecord
  class Base
    def self.between(criterion)
      scope = scoped
      criterion.each do |attribute, range|
        scope = scoped.where { (__send__(attribute) >= range.first) & (__send__(attribute) <= range.last) }
      end
      scope
    end
  end
end
