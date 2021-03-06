class Oauth2Verifier < OauthToken
  attr_accessor :state

  validates :user, presence: true

  def exchange!(params = {})
    OauthToken.transaction do
      token = Oauth2Token.create!(user: user, client_application: client_application, scope: scope)
      invalidate!
      token
    end
  end

  def code
    token
  end

  def redirect_url
    callback_url
  end

  def to_query
    q = "code=#{token}"
    q << "&state=#{URI.escape(state)}" if @state
    q
  end

  protected

  def generate_keys
    self.token         = OAuth::Helper.generate_key(20)[0, 20]
    self.expires_at    = 10.minutes.from_now
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
#  expires_at            :datetime
#  id                    :integer          not null, primary key
#  invalidated_at        :datetime
#  scope                 :string(255)
#  secret                :string(40)
#  token                 :string(40)
#  type                  :string(20)
#  updated_at            :datetime
#  user_id               :integer
#  verifier              :string(20)
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

