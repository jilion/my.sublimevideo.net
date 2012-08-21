require_dependency 'admin_role_methods'
require_dependency 'validators/admin_roles_validator'

class Admin < ActiveRecord::Base
  include AdminRoleMethods

  devise :database_authenticatable, :invitable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :lockable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :roles

  serialize :roles, Array

  # ================
  # = Associations =
  # ================

  has_many :mail_logs, class_name: "MailLog"

  # ===============
  # = Validations =
  # ===============

  validates :roles, admin_roles: true

  # ==========
  # = Scopes =
  # ==========

  scope :by_date, lambda { |way='desc'| order(:created_at.send(way)) }

end

# == Schema Information
#
# Table name: admins
#
#  created_at             :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(128)      default(""), not null
#  failed_attempts        :integer          default(0)
#  id                     :integer          not null, primary key
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string(60)
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  locked_at              :datetime
#  password_salt          :string(255)      default(""), not null
#  remember_created_at    :datetime
#  remember_token         :string(255)
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  roles                  :text
#  sign_in_count          :integer          default(0)
#  unconfirmed_email      :string(255)
#  updated_at             :datetime
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_invitation_token      (invitation_token)
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

