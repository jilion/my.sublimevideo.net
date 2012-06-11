module StatTimeline

  class Invoice
    def self.timeline(invoices, start_time, end_time, options = {})
      invoices = invoices.group_by { |i| i.created_at.to_date }

      (start_time.to_date..end_time.to_date).inject([]) do |amounts, day|
        amounts << (invoices[day] ? invoices[day].sum { |i| i.amount } : 0)
      end
    end
  end

end
