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

  # Implement this to return a hash or array of the capabilities the access token has
  # This is particularly useful if you have implemented user defined permissions.
  # def capabilities
  #   {:invalidate=>"/oauth/invalidate",:capabilities=>"/oauth/capabilities"}
  # end

  def as_json(options={})
    { access_token: token }
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
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

