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
#  id         :integer         not null, primary key
#  user_id    :integer
#  public_key :string(255)
#  secret_key :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_api_tokens_on_public_key  (public_key) UNIQUE
#  index_api_tokens_on_secret_key  (secret_key) UNIQUE
#

