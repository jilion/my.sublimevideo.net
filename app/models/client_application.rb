class ClientApplication < ActiveRecord::Base

  attr_accessor :token_callback_url

  # ================
  # = Associations =
  # ================

  belongs_to :user

  has_many :tokens, class_name: "OauthToken", dependent: :delete_all
  has_many :oauth2_verifiers, dependent: :delete_all

  # ===============
  # = Validations =
  # ===============

  validates :name, :url, :key, :secret, presence: true
  validates :key, uniqueness: true

  validates :url, format: { with: /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i }
  validates :support_url, format: { with: /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, allow_blank: true }
  validates :callback_url, format: { with: /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, allow_blank: true }

  # =============
  # = Callbacks =
  # =============

  before_validation :generate_keys, on: :create

  # =================
  # = Class Methods =
  # =================

  def self.find_token(token_key)
    token = OauthToken.includes(:client_application).find_by_token(token_key)
    if token && token.authorized?
      token
    else
      nil
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def oauth_server
    @oauth_server ||= OAuth::Server.new("https://my.sublimevideo.net")
  end

  def credentials
    @oauth_client ||= OAuth::Consumer.new(key, secret)
  end

protected

  def generate_keys
    self.key    = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end

end
# == Schema Information
#
# Table name: client_applications
#
#  id           :integer         not null, primary key
#  user_id      :integer
#  name         :string(255)
#  url          :string(255)
#  support_url  :string(255)
#  callback_url :string(255)
#  key          :string(40)
#  secret       :string(40)
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_client_applications_on_key  (key) UNIQUE
#

