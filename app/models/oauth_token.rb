class OauthToken < ActiveRecord::Base

  attr_accessible :user, :client_application, :scope

  belongs_to :user
  belongs_to :client_application

  before_validation :generate_keys, on: :create

  validates :client_application, :token, presence: true
  validates :token, uniqueness: true

  scope :valid, where{ (invalidated_at == nil) & (authorized_at != nil) }

  def invalidated?
    invalidated_at?
  end

  def invalidate!
    update_attribute(:invalidated_at, Time.now.utc)
  end

  def authorized?
    authorized_at? && !invalidated_at?
  end

  def to_query
    "oauth_token=#{token}&oauth_token_secret=#{secret}"
  end

  protected

  def generate_keys
    self.token  = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end

end

# == Schema Information
#
# Table name: oauth_tokens
#
#  authorized_at         :datetime
#  callback_url          :string(255)
#  client_application_id :integer
#  created_at            :datetime         not null
#  id                    :integer          not null, primary key
#  invalidated_at        :datetime
#  scope                 :string(255)
#  secret                :string(40)
#  token                 :string(40)
#  type                  :string(20)
#  updated_at            :datetime         not null
#  user_id               :integer
#  valid_to              :datetime
#  verifier              :string(20)
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

