class OauthToken < ActiveRecord::Base

  # ================
  # = Associations =
  # ================

  belongs_to :user
  belongs_to :client_application

  # ===============
  # = Validations =
  # ===============

  validates :client_application, :token, presence: true
  validates :token, uniqueness: true

  # =============
  # = Callbacks =
  # =============

  before_validation :generate_keys, on: :create

  # ==========
  # = Scopes =
  # ==========

  scope :valid, where { (invalidated_at == nil) & (authorized_at != nil) }

  # ====================
  # = Instance Methods =
  # ====================

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
#  id                    :integer         not null, primary key
#  type                  :string(20)
#  user_id               :integer
#  client_application_id :integer
#  token                 :string(40)
#  secret                :string(40)
#  callback_url          :string(255)
#  verifier              :string(20)
#  scope                 :string(255)
#  authorized_at         :datetime
#  invalidated_at        :datetime
#  valid_to              :datetime
#  created_at            :datetime        not null
#  updated_at            :datetime        not null
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#
