require 'spec_helper'

describe InvoiceItem do

  describe "Associations" do
    it { should belong_to :invoice }
    it { should have_one :site } # through :invoice
    it { should have_one :user } # through :site

    it { should belong_to :deal }

    it { should belong_to :item }
  end # Associations

  describe "Validations" do
    [:invoice, :item].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    # it { should validate_presence_of(:invoice) }
    it { should validate_presence_of(:item_type) }
    it { should validate_presence_of(:item_id) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }

    it { should validate_numericality_of(:price) }
    it { should validate_numericality_of(:amount) }
  end # Validations

  describe 'Callbacks' do
    it 'sets price and amount before validation' do
      invoice_item = build(:invoice_item, item: create(:addon, price: 1000))

      invoice_item.price.should be_nil
      invoice_item.amount.should be_nil

      invoice_item.should be_valid

      invoice_item.price.should eq 1000
      invoice_item.amount.should eq 1000
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

