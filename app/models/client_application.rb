class ClientApplication < ActiveRecord::Base

  attr_accessible :name, :url, :callback_url, :support_url
  attr_accessor :token_callback_url

  belongs_to :user

  has_many :tokens, class_name: 'OauthToken', dependent: :delete_all
  has_many :oauth2_verifiers, dependent: :delete_all

  before_validation :generate_keys, on: :create

  validates :name, :url, :key, :secret, presence: true
  validates :key, uniqueness: true

  validates :url, format: { with: URI::regexp(%w[http https]) }
  validates :support_url, :callback_url, format: { with: URI::regexp(%w[http https]), allow_blank: true }

  def self.find_token(token_key)
    token = OauthToken.includes(:client_application).find_by_token(token_key)
    if token && token.authorized?
      token
    else
      nil
    end
  end

  def oauth_server
    @oauth_server ||= OAuth::Server.new('https://my.sublimevideo.net')
  end

  def credentials
    @oauth_client ||= OAuth::Consumer.new(key, secret)
  end

protected

  def generate_keys
    self.key    = OAuth::Helper.generate_key(40)[0, 40]
    self.secret = OAuth::Helper.generate_key(40)[0, 40]
  end

end

# == Schema Information
#
# Table name: client_applications
#
#  callback_url :string(255)
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  key          :string(40)
#  name         :string(255)
#  secret       :string(40)
#  support_url  :string(255)
#  updated_at   :datetime         not null
#  url          :string(255)
#  user_id      :integer
#
# Indexes
#
#  index_client_applications_on_key  (key) UNIQUE
#

