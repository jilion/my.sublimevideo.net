class InvoicesPopulator < Populator

  def execute
    PopulateHelpers.empty_tables('invoices_transactions', InvoiceItem, Invoice, Transaction)

    User.all.each do |user|
      user.sites.active.each do |site|
        timestamp = site.created_at
        while timestamp < Time.now.utc do
          timestamp += 1.month
          Timecop.travel(timestamp.end_of_month) do
            creator = InvoiceCreator.build_for_month(Time.now.utc, site).tap { |s| s.save }
            creator.invoice.succeed if creator.invoice.persisted?
          end
        end
      end
      puts "#{user.invoices.count} invoices created for #{user.name}"
    end
  end

end
