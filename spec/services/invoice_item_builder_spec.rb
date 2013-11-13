require 'fast_spec_helper'

require 'services/invoice_item_builder'

describe InvoiceItemBuilder do

  describe '._full_days' do
    it { expect(described_class._full_days(Time.utc(2013, 3, 1), Time.utc(2013, 3, 1, 23, 59, 59) - 1)).to eq 0 }
    it { expect(described_class._full_days(Time.utc(2013, 3, 1), Time.utc(2013, 3, 1, 23, 59, 59))).to eq 1 }
    it { expect(described_class._full_days(Time.utc(2013, 3, 1), Time.utc(2013, 3, 1, 23, 59, 59) + 1)).to eq 1 }
  end

end
