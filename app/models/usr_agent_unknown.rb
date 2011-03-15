class UsrAgentUnknown
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_agent
  field :unknowns, :type => Array
end
