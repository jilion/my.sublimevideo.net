class InvoiceItem < ActiveRecord::Base
  
  attr_accessible :site, :item, :price, :amount, :started_on, :ended_on, :info
  
  serialize :info
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :site
  belongs_to :invoice
  belongs_to :item, :polymorphic => true
  
  delegate :user, :to => :site
  
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
  validates :started_on, :presence => true
  validates :ended_on,   :presence => true
  validates :item_id,    :presence => true
  validates :price,      :presence => true, :numericality => true
  validates :amount,     :numericality => true, :allow_nil => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = Class Methods =
  # =================
  
  def self.process_invoice_items_for_sites_billable_on(date) # utc date!
    
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def site=(site)
    if site.present?
      self.site_id = site.id
      self.invoice = site.user.open_invoice
    end
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

