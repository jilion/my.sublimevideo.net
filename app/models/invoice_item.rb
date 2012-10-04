class InvoiceItem < ActiveRecord::Base

  attr_accessor   :deduct
  attr_accessible :invoice, :item, :deduct

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

  validates :item_type,  presence: true
  validates :item_id,    presence: true
  validates :started_at, presence: true
  validates :ended_at,   presence: true
  validates :price,      presence: true, numericality: true
  validates :amount,     presence: true, numericality: true

  before_validation ->(invoice_item) do
    if price = invoice_item.item.try(:price)
      invoice_item.price  = price
      invoice_item.amount = (deduct ? -1 : 1) * price
    end
  end

end

# == Schema Information
#
# Table name: invoice_items
#
#  amount                :integer
#  created_at            :datetime         not null
#  deal_id               :integer
#  discounted_percentage :float
#  ended_at              :datetime
#  id                    :integer          not null, primary key
#  invoice_id            :integer
#  item_id               :integer
#  item_type             :string(255)
#  price                 :integer
#  started_at            :datetime
#  type                  :string(255)
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_invoice_items_on_deal_id                (deal_id)
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

