class Invoice < ActiveRecord::Base
  
  # attr_accessible ...
  
  uniquify :reference, :chars => Array('A'..'Z') + Array('1'..'9')
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many :invoice_items
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,       :presence => true
  validates :started_on, :presence => true
  validates :ended_on,   :presence => true
  validates :amount,     :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :current do
  end
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
end
# == Schema Information
#
# Table name: invoices
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  reference  :string(255)
#  state      :string(255)
#  started_on :date
#  ended_on   :date
#  charged_at :datetime
#  amount     :integer         default(0)
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

