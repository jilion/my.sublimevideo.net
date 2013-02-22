module Searchable
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def search(q, or_conditions = [])
      scopes = scoped
      associations = self.reflect_on_all_associations(:belongs_to) + self.reflect_on_all_associations(:has_one)
      associations.each do |association|
        case association.name
        when :user
          or_conditions << 'lower(users.email) =~ lower("%#{q}%")'
          or_conditions << 'lower(users.name) =~ lower("%#{q}%")'
          scopes = scopes.joins(:user)
        when :site
          or_conditions << 'lower(sites.hostname) =~ lower("%#{q}%")'
          or_conditions << 'lower(sites.dev_hostnames) =~ lower("%#{q}%")'
          scopes = scopes.joins(:site)
        end
      end

      puts eval("scopes.where { #{or_conditions.map{ |c| "(#{c})" }.join(' | ')} }").to_sql
      eval "scopes.where { #{or_conditions.map{ |c| "(#{c})" }.join(' | ')} }"
    end
  end

end