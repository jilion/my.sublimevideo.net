module SiteUsagesHelper

  def get_usages_hash(site_or_user, options = {})
    usages_hash = Hash.new { |h, k| h[k] = {} }
    site_id = site_or_user.respond_to?(:site_ids) ? site_or_user.site_ids : [site_or_user.id]
    %w[loader_hits player_hits main_player_hits main_player_hits_cached extra_player_hits extra_player_hits_cached dev_player_hits dev_player_hits_cached invalid_player_hits invalid_player_hits_cached flash_hits requests_s3 traffic_s3 traffic_voxcast].map(&:to_sym).each do |usage_name|
      usages_hash[:total][usage_name] = begin
        SiteUsage.any_in(site_id: site_id).sum(usage_name).to_i
      rescue
        0
      end

      if options[:last_30_days]
        usages_hash[:last_30_days][usage_name] = SiteUsage.between(day: (Time.now.utc.midnight - 30.days)..Time.now.utc.midnight).any_in(site_id: site_id).sum(usage_name).to_i
      end

      if options[:from] && options[:to]
        usages_hash[:range][usage_name] = SiteUsage.between(day: options[:from]..options[:to]).any_in(site_id: site_id).sum(usage_name).to_i
      end
    end
    usages_hash
  end

end
