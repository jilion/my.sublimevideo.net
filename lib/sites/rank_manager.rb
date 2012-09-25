require_dependency 'page_rankr'

module Sites
  class RankManager

    def self.set_ranks(site_id)
      site = Site.find(site_id)

      begin
        ranks = PageRankr.ranks("http://#{site.hostname}", :alexa_global, :google)
        site.google_rank = ranks[:google] || 0
        site.alexa_rank  = ranks[:alexa_global]
      rescue
        site.google_rank = 0
        site.alexa_rank  = 0
      end

      site.save
    end

  end
end
