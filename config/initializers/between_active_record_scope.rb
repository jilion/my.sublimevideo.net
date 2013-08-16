module ActiveRecord
  class Base
    def self.between(criterion)
      scope = all
      criterion.each do |attribute, range|
        scope = all.where { (__send__(attribute) >= range.first) & (__send__(attribute) <= range.last) }
      end
      scope
    end
  end
end
