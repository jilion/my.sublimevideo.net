class Invoice::Sites < Array
  attr_reader :amount, :loader_amount, :js_amount, :loader_hits, :js_hits
  
  def initialize(invoice, options = {})
    @sites = collect_sites_hits(invoice, options)
    calculate_and_set_hits
    calculate_and_set_amounts
    super(@sites)
  end
  
private
  
  def collect_sites_hits(invoice, options = {})
    if options[:from_cache]
      invoice.user.sites.collect do |site|
        { :id => site.id,
          :hostname => site.hostname,
          :loader_hits => site.loader_hits_cache,
          :js_hits => site.js_hits_cache
        }
      end
    end
  end
  
  def calculate_and_set_hits
    @loader_hits = @sites.sum { |site| site[:loader_hits] }
    @js_hits = @sites.sum { |site| site[:js_hits] }
  end
  
  def calculate_and_set_amounts
    # TODO, now 1 hit = 1 cent
    @sites.each do |site|
      site[:loader_amount] = site[:loader_hits]
      site[:js_amount] = site[:js_hits]
    end
    @loader_amount = @loader_hits
    @js_amount = @js_hits
    @amount = @loader_amount + @js_amount
  end
  
end