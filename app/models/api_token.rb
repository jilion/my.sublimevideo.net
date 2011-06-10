class ApiToken < ActiveRecord::Base

  uniquify :public_key, :chars => Array('A'..'Z') + Array('0'..'9'), :length => 20
  uniquify :secret_key, :length => 40

  # ================
  # = Associations =
  # ================

  belongs_to :user

  # =============
  # = Callbacks =
  # =============

  # ===============
  # = Validations =
  # ===============

  validates :user_id, :presence => true

end

# == Schema Information
#
# Table name: api_tokens
#
#  id                   :integer         not null, primary key
#  user_id              :integer
#  sign_in_count        :integer         default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  authentication_token :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_api_tokens_on_authentication_token  (authentication_token) UNIQUE
#

