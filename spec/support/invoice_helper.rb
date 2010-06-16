
# Need video invoice for this helper (used in trial_spec)
def create_invoice(options = {})
  options[:loader_hits] ||= 12
  options[:player_hits] ||= 21
  
  user  = Factory(:user, :invoices_count => 0, :created_at => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
  site = Factory(:site, :user => user, :loader_hits_cache => options[:loader_hits], :player_hits_cache => options[:player_hits])
  VCR.use_cassette('one_saved_logs') do
    @log = Factory(:log_voxcast, :started_at => 1.month.ago, :ended_at => 1.month.ago + 3.days)
  end
  Factory(:site_usage, :site => site, :log => @log, :loader_hits => options[:loader_hits], :player_hits => options[:player_hits])
  
  invoice = Factory(:invoice, :user => user).reload
  invoice.calculate if options[:calculate]
  invoice
end