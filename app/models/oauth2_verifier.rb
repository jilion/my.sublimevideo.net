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
