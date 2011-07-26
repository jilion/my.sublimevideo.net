require 'oauth'

class ClientApplication < ActiveRecord::Base

  attr_accessor :token_callback_url

  # ================
  # = Associations =
  # ================

  belongs_to :user

  has_many :tokens, :class_name => "OauthToken", :dependent => :delete_all
  has_many :access_tokens, :dependent => :delete_all
  has_many :oauth2_verifiers, :dependent => :delete_all
  has_many :oauth_tokens, :dependent => :delete_all

  # =============
  # = Callbacks =
  # =============

  before_validation :generate_keys, :on => :create

  # ===============
  # = Validations =
  # ===============

  validates :name, :url, :key, :secret, :presence => true
  validates :key, :uniqueness => true

  validates :url, :format => { :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i }
  validates :support_url, :format => { :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank => true }
  validates :callback_url, :format => { :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank => true }

  # =================
  # = Class Methods =
  # =================

  def self.find_token(token_key)
    token = OauthToken.find_by_token(token_key, :include => :client_application)
    if token && token.authorized?
      token
    else
      nil
    end
  end

  def self.verify_request(request, options = {}, &block)
    begin
      signature = OAuth::Signature.build(request, options, &block)
      return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)
      value = signature.verify
      value
    rescue OAuth::Signature::UnknownSignatureMethod => e
      false
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

  # If your application requires passing in extra parameters handle it here
  def create_request_token(params={})
    RequestToken.create(client_application: self, callback_url: self.token_callback_url)
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
#  name         :string(255)
#  url          :string(255)
#  support_url  :string(255)
#  callback_url :string(255)
#  key          :string(40)
#  secret       :string(40)
#  user_id      :integer
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_client_applications_on_key  (key) UNIQUE
#

