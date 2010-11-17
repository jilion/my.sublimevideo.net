class InvoiceItem < ActiveRecord::Base
  
  attr_accessible :site_id, :item_type, :item_id, :price, :amount, :info
  
  serialize :info
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :site
  belongs_to :invoice
  belongs_to :item, :polymorphic => true
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :not_canceled, where(:canceled_at => nil)
  scope :canceled,     where(:canceled_at.ne => nil)
  
  # ===============
  # = Validations =
  # ===============
  
  validates :site,       :presence => true
  validates :invoice,    :presence => true
  validates :item_type,  :presence => true
  validates :item_id,    :presence => true
  validates :price,      :presence => true, :numericality => true
  validates :amount,     :numericality => true, :allow_nil => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_started_and_ended_on
  
  # =================
  # = State Machine =
  # =================
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
private
  
  def set_started_and_ended_on
    self.started_on = Time.now.utc.to_date
    self.ended_on   = 1.send(item.term_type).from_now.to_date
  end
  
end



# == Schema Information
#
# Table name: invoice_items
#
#  id          :integer         not null, primary key
#  type        :string(255)
#  site_id     :integer
#  invoice_id  :integer
#  item_type   :string(255)
#  item_id     :integer
#  started_on  :date
#  ended_on    :date
#  canceled_at :datetime
#  price       :integer
#  amount      :integer
#  info        :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#

