module Searchable
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def search(q)
      scopes, or_conditions = scoped, additional_or_conditions
      associations = self.reflect_on_all_associations(:belongs_to) + self.reflect_on_all_associations(:has_one) + self.reflect_on_all_associations(:has_many)
      associations.each do |association|
        case association.name
        when :user
          %w[email name].each { |field| or_conditions << ("lower(users.#{field}) =~ " 'lower("%#{q}%")') }
          scopes = scopes.joins(:user)
        when :site, :sites
          %w[hostname extra_hostnames staging_hostnames dev_hostnames].each do |field|
            or_conditions << ("lower(sites.#{field}) =~ " 'lower("%#{q}%")')
          end
          scopes = scopes.includes(association.name)
        end
      end

      eval "scopes.where { #{or_conditions.map{ |c| "(#{c})" }.join(' | ')} }"
    end

    def additional_or_conditions
      []
    end
  end

end