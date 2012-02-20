require 'csv'

# coding: utf-8
namespace :export do
  namespace :stats do

    desc "Export VideoStats to csv"
    task videos: :environment do
      timed do
        counter = 0
        site_token = '2xrynuh2' # schooltube.com
        CSV.open("#{ENV['HOME']}/Desktop/video_stats-#{site_token}.csv", "wb") do |csv|
          csv << ['uid', 'name', 'loads_count', 'views_count', 'embed_loads_count', 'embed_views_count']
          VideoTag.where(st: site_token, uo: 'a').each do |video_tag|
            stats = Stat::Video.where(st: site_token, u: video_tag.u, d: { "$ne" => nil }).entries
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
      #   criteria.each do |video_tag|
      #     case video_tag.uo
      #     when 's'
      #       video_crc = video_tag.cs.first
      #       if video_tag.s[video_crc]
      #         video_source = video_tag.s[video_crc]['u']
      #       else
      #         video_crc, hash = video_tag.s.first
      #         video_source = hash['u']
      #       end
      #
      #       if video_source.include?('?')
      #         good_video_crc = Zlib.crc32(video_source.match(/^(.*)\?/)[1]).to_s(16)
      #         if good_video_crc != video_crc
      #           bad_video_stat_crit  = Stat::Video.where(st: video_tag.st, u: video_crc)
      #           bad_video_stat_count = bad_video_stat_crit.count
      #           case bad_video_stat_count
      #           when 1
      #             bad_video_stat = bad_video_stat_crit.first
      #             if good_video_stat = Stat::Video.where(st: video_tag.st, u: good_video_crc, d: bad_video_stat.d).first
      #               merge_video_stat(bad_video_stat, good_video_stat)
      #               bad_video_stat.delete
      #             else
      #               update_bad_video_stat(bad_video_stat, good_video_crc)
      #             end
      #
      #             if VideoTag.where(st: video_tag.st, u: good_video_crc).exists?
      #               video_tag.delete
      #             else
      #               update_bad_video_tag(video_tag, good_video_crc)
      #             end
      #           when 0
      #             # nothing special to do
      #             video_tag.delete
      #           end
      #         end
      #       end
      #     else # nil
      #       bad_video_stat_crit = Stat::Video.where(st: video_tag.st, u: video_tag.u)
      #       bad_video_stat_count = bad_video_stat_crit.count
      #       if bad_video_stat_count <= 1
      #         bad_video_stat_crit.delete
      #         video_tag.delete
      #       end
      #     end
      #   end
      # end
  #   end
  # end

#   def merge_video_stat(bad_video_stat, good_video_stat)
#     inc = {}
#     bad_video_stat.bp.each { |k, v| inc["bp.#{k}"] = v }
#     bad_video_stat.md.each { |k1, v| v.each { |k, v| inc["md.#{k1}.#{k}"] = v } }
#     bad_video_stat.vl.each { |k, v| inc["vl.#{k}"] = v }
#     bad_video_stat.vv.each { |k, v| inc["vv.#{k}"] = v }
#     inc["vs.#{good_video_stat.u}"] = bad_video_stat.vs[bad_video_stat.u]
#     Stat::Video.collection.update({ st: good_video_stat.st, u: good_video_stat.u, d: good_video_stat.d.to_time }, { "$inc" => inc }, upsert: true)
#   end
#
#   def update_bad_video_stat(bad_video_stat, good_video_crc)
#     bad_video_stat.vs = { good_video_crc => bad_video_stat.vs[bad_video_stat.u] }
#     bad_video_stat.u = good_video_crc
#     bad_video_stat.save!
#   end
#
#   def update_bad_video_tag(bad_video_tag, good_video_crc)
#     if source = bad_video_tag.s[bad_video_tag.u]
#       bad_video_tag.s = { good_video_crc => source }
#     end
#     bad_video_tag.cs = [good_video_crc]
#     bad_video_tag.u = good_video_crc
#     bad_video_tag.save!
#   end
#
# end