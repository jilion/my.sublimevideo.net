class Oauth2Verifier < OauthToken

  # ===============
  # = Validations =
  # ===============

  validates :user, presence: true

  # ====================
  # = Instance Methods =
  # ====================

  def exchange!(params={})
    OauthToken.transaction do
      token = Oauth2Token.create!(user: user, client_application: client_application)
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

  protected

  def generate_keys
    self.token         = OAuth::Helper.generate_key(20)[0,20]
    self.valid_to      = 10.minutes.from_now
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

