module Searchable
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def search(q)
      scopes, or_conditions = all, additional_or_conditions(q)
      associations = self.reflect_on_all_associations(:belongs_to) + self.reflect_on_all_associations(:has_one) + self.reflect_on_all_associations(:has_many)

      associations.each do |association|
        case association.name
        when :user
          %w[email name].each { |field| or_conditions << ("users.#{field} ILIKE '%#{q}%'") }
          scopes = scopes.joins(:user)
        when :site, :sites
          %w[hostname extra_hostnames staging_hostnames dev_hostnames].each do |field|
            or_conditions << ("sites.#{field} ILIKE '%#{q}%'")
          end
          scopes = scopes.includes(association.name).references(association.name)
        end
      end

      scopes.where(or_conditions.join(' OR '))
    end

    def additional_or_conditions(q)
      []
    end

    def lower_and_match_fields(table, fields, q)
      fields.reduce([]) { |a, e| a << ("#{table}.#{e} ILIKE '%#{q}%'") }
    end
  end

end
