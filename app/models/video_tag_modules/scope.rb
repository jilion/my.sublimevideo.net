module VideoTagModules::Scope
  extend ActiveSupport::Concern

  included do
    # search
    scope :custom_search, lambda { |query|
      where(:$or => [
        { n: /.*#{query}.*/i },
        { u: /.*#{query}.*/i }
      ])
    }

    # filter
    scope :last_30_days_active, where(updated_at: { :$gte => 30.days.ago.midnight })
    scope :last_90_days_active, where(updated_at: { :$gte => 90.days.ago.midnight })
    scope :hosted_on_sublimevideo, where({}) # TODO Thibaud
    scope :not_hosted_on_sublimevideo, where({}) # TODO Thibaud
    scope :inactive, where(state: 'inactive')
    scope :active, where(uo: { :$ne => nil }, no: { :$ne => nil })
    # scope :all, where({}) # TODO Thibaud

    # sort
    scope :by_name,  lambda { |way='desc'| order_by([:n, way.to_sym]) }
    scope :by_date,  lambda { |way='desc'| order_by([:created_at, way.to_sym]) }
    scope :by_state, lambda { |way='desc'| order_by([:state, way.to_sym]) }
  end
end
