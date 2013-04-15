class InvoicesTimelineBuilder
  attr_reader :invoices, :start_time, :end_time

  def initialize(invoices, start_time, end_time)
    @invoices   = invoices.group_by { |i| i.created_at.to_date }
    @start_time = start_time
    @end_time   = end_time
  end

  def timeline
    (start_time.to_date..end_time.to_date).reduce([]) do |a, day|
      a << (invoices[day] ? invoices[day].sum { |i| i.amount } : 0)
    end
  end
end
