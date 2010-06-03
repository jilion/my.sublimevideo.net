# == Schema Information
#
# Table name: users
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  password_salt        :string(255)     default(""), not null
#  full_name            :string(255)
#  confirmation_token   :string(255)
#  confirmed_at         :datetime
#  confirmation_sent_at :datetime
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
#  invoices_count       :integer         default(0)
#  last_invoiced_on     :date
#  next_invoiced_on     :date
#  trial_finished_at    :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable
  
  attr_accessible :full_name, :email, :password
  
  # ================
  # = Associations =
  # ================
  
  has_many :sites
  has_many :videos, :class_name => 'VideoOriginal'
  has_many :invoices
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :full_name, :presence => true
  validates :email,     :presence => true, :uniqueness => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_next_invoiced_on
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def welcome?
    sites.empty?
    # TODO And if user has a credit card
  end
  
  def credit_card?
    false
  end
  
  def trial?
    # TODO Rewrite, don't suppose that only first invoice is trial
    trial_finished_at.nil? # && trial_loader_hits < Trial.free_loader_hits && trial_player_hits < Trial.free_player_hits
  end
  
  def trial_loader_hits
    # TODO Rewrite, calculate sum of invoices.sites.loader_hits
    Invoice.current(self).sites.loader_hits
  end
  def trial_player_hits
    # TODO Rewrite, calculate sum of invoices.sites.player_hits
    Invoice.current(self).sites.player_hits
  end
  
  def trial_usage_percentage
    loader_hits_percentage = ((trial_loader_hits / Trial.free_loader_hits.to_f) * 100).to_i
    player_hits_percentage = ((trial_player_hits / Trial.free_player_hits.to_f) * 100).to_i
    loader_hits_percentage > player_hits_percentage ? loader_hits_percentage : player_hits_percentage
  end
  
private
  
  # before_create
  def set_next_invoiced_on
    self.next_invoiced_on ||= Time.now.utc.to_date + 1.month
  end
  
end
