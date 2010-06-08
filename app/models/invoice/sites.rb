class Invoice::Sites < Array
  attr_reader :amount, :loader_amount, :player_amount, :loader_hits, :player_hits
  
  def initialize(invoice, options = {})
    @sites = collect_sites_hits(invoice, options)
    calculate_and_set_hits
    calculate_and_set_amounts(invoice)
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
    else
      invoice.user.sites.collect do |site|
        { :id => site.id,
          :hostname => site.hostname,
          # Warning big request here if site_usages not compacted
          :loader_hits => site.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:loader_hits),
          :player_hits => site.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:player_hits)
        }
      end
    end
  end
  
  def calculate_and_set_hits
    @loader_hits = @sites.sum { |site| site[:loader_hits] }
    @player_hits = @sites.sum { |site| site[:player_hits] }
  end
  
  def calculate_and_set_amounts(invoice)
    if invoice.user.trial_ended_at.nil? || (invoice.user.trial_ended_at > invoice.started_on && invoice.user.trial_ended_at < invoice.ended_on)
      # TODO Rewrite, test if trial_ended_at is inside the invoice interval & calculate how much free hits remaining 
      loader_hits = @loader_hits > User::Trial.free_loader_hits ? @loader_hits - User::Trial.free_loader_hits : 0
      player_hits = @player_hits > User::Trial.free_player_hits ? @player_hits - User::Trial.free_player_hits : 0
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