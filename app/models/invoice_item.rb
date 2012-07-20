class InvoiceItem < ActiveRecord::Base

  autoload :Plan, 'invoice_item/plan'

  attr_accessible :invoice, :item

  # ================
  # = Associations =
  # ================

  belongs_to :invoice, counter_cache: true
  has_one :site, through: :invoice
  has_one :user, through: :site

  belongs_to :item, polymorphic: true

  belongs_to :deal

  delegate :site, to: :invoice
  delegate :user, to: :site

  # ===============
  # = Validations =
  # ===============

  validates :invoice,    presence: true
  validates :item_type,  presence: true
  validates :item_id,    presence: true
  validates :started_at, presence: true
  validates :ended_at,   presence: true
  validates :price,      presence: true, numericality: true
  validates :amount,     presence: true, numericality: true

end

# == Schema Information
#
# Table name: invoice_items
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  invoice_id            :integer
#  item_type             :string(255)
#  item_id               :integer
#  started_at            :datetime
#  ended_at              :datetime
#  discounted_percentage :float
#  price                 :integer
#  amount                :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  deal_id               :integer
#
# Indexes
#
#  index_invoice_items_on_deal_id                (deal_id)
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

