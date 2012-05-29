require 'csv'

# coding: utf-8
namespace :export do
  namespace :stats do

    desc "Export VideoStats to csv"
    task videos: :environment do
      timed do
        counter = 0
        # site_token = '2xrynuh2' # schooltube.com (uo: 'a')
        site_token = 'srkkdods' # twit.tv (n: { '$ne' => nil })
        CSV.open("#{ENV['HOME']}/Desktop/video_stats-#{site_token}.csv", "wb") do |csv|
          csv << ['uid', 'name', 'loads_count', 'views_count', 'embed_loads_count', 'embed_views_count']
          VideoTag.where(st: site_token).active.each do |video_tag|
            stats = Stat::Video::Day.where(st: site_token, u: video_tag.u).entries
            vl = hashes_values_sum(stats, :vl)
            vv = hashes_values_sum(stats, :vv)
            csv << [video_tag.u, video_tag.n, vl['m'].to_i + vl['e'].to_i, vv['m'].to_i + vv['e'].to_i, vl['em'].to_i, vv['em'].to_i]
            counter += 1
            p "#{counter} video tags processed" if counter%1000 == 0
          end
        end
      end
    end

    def hashes_values_sum(stats, attribute)
      stats.map(&attribute).inject({}) do |memo, el|
        memo.merge(el) { |k, old_v, new_v| old_v + new_v }
      end
    end

  end
end
