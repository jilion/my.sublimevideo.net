require 'spec_helper'
require File.join(Rails.root, 'db', 'migrate', '20130528145752_new_addons_system')

describe NewAddonsSystem do
  describe '#up' do
    context 'with some billable items and billable item activities' do
      before do
        @bi  = create(:billable_item, item: create(:design))
        @bia = create(:billable_item_activity, item: create(:design))
        build(:paid_invoice).tap { |i|
          @dii_id = create(:design_invoice_item, invoice: i, amount: 2).id
        }.save
        ActiveRecord::Base.connection.execute <<-EOS
        UPDATE billable_items
        SET item_type = 'App::Design'
        WHERE item_type = 'Design'
        EOS
        ActiveRecord::Base.connection.execute <<-EOS
        UPDATE billable_item_activities
        SET item_type = 'App::Design'
        WHERE item_type = 'Design'
        EOS
        ActiveRecord::Base.connection.execute <<-EOS
        UPDATE invoice_items
        SET type = 'InvoiceItem::AppDesign', item_type = 'AppDesign'
        WHERE type = 'InvoiceItem::Design'
        EOS
        @bi.reload.item_type.should eq 'App::Design'
        @bia.reload.item_type.should eq 'App::Design'
        described_class.new.down
      end

      it 'updates all the BillableItem and BillableItemActivity with item_type == "App::Design" to "Design"' do
        described_class.new.up
        @bi.reload.item_type.should eq 'Design'
        @bia.reload.item_type.should eq 'Design'
        @dii = InvoiceItem::Design.find(@dii_id)
        @dii.type.should eq 'InvoiceItem::Design'
        @dii.item_type.should eq 'Design'
      end
    end
  end

  describe '#down' do
    it 'does nothing' do
      true
    end
  end
end