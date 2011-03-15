class Admin < ActiveRecord::Base
  
  devise :database_authenticatable, :invitable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :lockable
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 25
  
  attr_accessible :email, :password, :password_confirmation, :remember_me
  
  # ================
  # = Associations =
  # ================
  
  has_many :mail_logs, :class_name => "Mail::Log"
  
  # ==========
  # = Scopes =
  # ==========
  scope :by_date, lambda { |way = 'desc'| order("#{Admin.quoted_table_name}.created_at #{way}") }
  
end



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
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_invitation_token      (invitation_token)
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

