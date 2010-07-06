# == Schema Information
#
# Table name: admins
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  password_salt        :string(255)     default(""), not null
#  reset_password_token :string(255)
#  remember_token       :string(255)
#  remember_created_at  :datetime
#  sign_in_count        :integer         default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  failed_attempts      :integer         default(0)
#  locked_at            :datetime
#  invitation_token     :string(20)
#  invitation_sent_at   :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

class Admin < ActiveRecord::Base
  devise :database_authenticatable, :invitable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :lockable
  
  attr_accessible :email, :password, :password_confirmation
end