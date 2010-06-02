class Invoice::Sites < Array
  attr_reader :amount, :loader_amount, :player_amount, :loader_hits, :player_hits
  
  def initialize(invoice, options = {})
    @sites = collect_sites_hits(invoice, options)
    calculate_and_set_hits
    calculate_and_set_amounts(invoice.user)
    super(@sites)
  end
  
private
  
  def collect_sites_hits(invoice, options = {})
    if options[:from_cache]
      invoice.user.sites.collect do |site|
        { :id => site.id,
          :hostname => site.hostname,
          :loader_hits => site.loader_hits_cache,
          :player_hits => site.player_hits_cache
        }
      end
    end
  end
  
  def calculate_and_set_hits
    @loader_hits = @sites.sum { |site| site[:loader_hits] }
    @player_hits = @sites.sum { |site| site[:player_hits] }
  end
  
  def calculate_and_set_amounts(user)
    if user.invoices_count.zero?
      loader_hits = @loader_hits > Trial.free_loader_hits ? @loader_hits - Trial.free_loader_hits : 0
      player_hits = @player_hits > Trial.free_player_hits ? @player_hits - Trial.free_player_hits : 0
    else
      loader_hits = @loader_hits
      player_hits = @player_hits
    end
    
    # TODO, now 1 hit = 1 cent
    @sites.each do |site|
      site[:loader_amount] = site[:loader_hits]
      site[:player_amount] = site[:player_hits]
    end
    @loader_amount = loader_hits
    @player_amount = player_hits
    @amount = @loader_amount + @player_amount
  end
  
end