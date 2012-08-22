class Oauth2Token < OauthToken

  # ===============
  # = Validations =
  # ===============

  validates :user, :secret, presence: true

  # =============
  # = Callbacks =
  # =============

  before_create :set_authorized_at

  # ====================
  # = Instance Methods =
  # ====================

  attr_accessor :state

  # Implement this to return a hash or array of the capabilities the access token has
  # This is particularly useful if you have implemented user defined permissions.
  # def capabilities
  #   {invalidate:"/oauth/invalidate",capabilities:"/oauth/capabilities"}
  # end

  def as_json(options = {})
    d = { access_token: token, token_type: 'bearer' }
    d[:expires_in] = expires_in if expires_at
    d
  end

  def to_query
    q = "access_token=#{token}&token_type=bearer"
    q << "&state=#{URI.escape(state)}" if @state
    q << "&expires_in=#{expires_in}" if expires_at
    q << "&scope=#{URI.escape(scope)}" if scope
    q
  end

  protected

  def set_authorized_at
    self.authorized_at = Time.now.utc
  end

end

# == Schema Information
#
# Table name: oauth_tokens
#
#  authorized_at         :datetime
#  callback_url          :string(255)
#  client_application_id :integer
#  created_at            :datetime
#  id                    :integer          not null, primary key
#  invalidated_at        :datetime
#  scope                 :string(255)
#  secret                :string(40)
#  token                 :string(40)
#  type                  :string(20)
#  updated_at            :datetime
#  user_id               :integer
#  valid_to              :datetime
#  verifier              :string(20)
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

