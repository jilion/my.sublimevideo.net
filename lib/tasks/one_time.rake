# coding: utf-8
require_dependency 'public_launch'

namespace :one_time do

  namespace :logs do
    desc "Reparse logs for site usages"
    task reparse: :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        SiteUsage.where(day: { "$gte" => beginning_of_month }).delete_all

        months_logs = Log.where(started_at: { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(priority: 299).parse_logs(months_logs_ids)
        puts "Delayed logs parsing from #{beginning_of_month}"
      end
    end

    desc "Reparse voxcast logs for user agent"
    task reparse_user_agent: :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        UsrAgent.where(month: { "$gte" => beginning_of_month }).delete_all

        months_logs = Log::Voxcast.where(started_at: { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(priority: 299).parse_logs_for_user_agents(months_logs_ids)
        puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
      end
    end

    task parse_unparsed_logs: :environment do
      count = Log::Voxcast.where(parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log.delay(priority: 100).parse_log(id) }
        skip += 1000
      end
    end

    # task reparse_logs_custom: :environment do
    #   from = Time.utc(2012, 2, 28)
    #   to   = Time.now.utc.change(sec: 0)
    #   LegacyStat::Site.d_after(from).delete_all
    #   LegacyStat::Video.d_after(from).delete_all
    #   SiteUsage.after(from).delete_all
    #   Log::Voxcast.where(started_at: { "$gte" => from, "$lte" => to }).entries.each do |log|
    #     log.parsed_at            = nil
    #     log.stats_parsed_at      = nil
    #     log.video_tags_parsed_at = nil
    #     log.safely.save
    #     Log::Voxcast.delay(priority: 30).parse_log_for_stats(log.id)
    #     Log::Voxcast.delay(priority: 30).parse_log(log.id)
    #     Log::Voxcast.delay(priority: 30).parse_log_for_video_tags(log.id)
    #   end
    #   Log::Amazon::S3::Licenses.where(started_at: { "$gte" => from, "$lte" => to }).entries.each do |log|
    #     log.parsed_at = nil
    #     log.safely.save
    #     Log::Amazon::S3::Licenses.delay(priority: 30).parse_log(log.id)
    #   end
    #   Log::Amazon::S3::Loaders.where(started_at: { "$gte" => from, "$lte" => to }).entries.each do |log|
    #     log.parsed_at = nil
    #     log.safely.save
    #     Log::Amazon::S3::Loaders.delay(priority: 30).parse_log(log.id)
    #   end
    #   Log::Amazon::S3::Player.where(started_at: { "$gte" => from, "$lte" => to }).entries.each do |log|
    #     log.parsed_at = nil
    #     log.safely.save
    #     Log::Amazon::S3::Player.delay(priority: 30).parse_log(log.id)
    #   end
    # end
  end

  namespace :users do
  end

  namespace :plans do
  end

  namespace :sites do
    desc "Reset sites caches"
    task reset_caches: :environment do
      timed { Site.all.each { |site| site.delay(priority: 400).reset_caches! } }
    end

    desc "Parse all unparsed user_agents logs"
    task parse_user_agents_logs: :environment do
      count = Log::Voxcast.where(user_agents_parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(user_agents_parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log::Voxcast.delay(priority: 90, run_at: 1.minute.from_now).parse_log_for_user_agents(id) }
        skip += 1000
      end
    end

    desc "Re-generate loader templates for all sites"
    task regenerate_loaders: :environment do
      timed { puts OneTime::Site.regenerate_templates(loader: true, license: false) }
    end

    desc "Re-generate license templates for all sites"
    task regenerate_licenses: :environment do
      timed { puts OneTime::Site.regenerate_templates(loader: false, license: true) }
    end

    desc "Re-generate loader and license templates for all sites"
    task regenerate_loaders_and_licenses: :environment do
      timed { puts OneTime::Site.regenerate_templates(loader: true, license: true) }
    end

    desc "Update last 30 days counters of all not archived sites"
    task update_last_30_days_counters_for_not_archived_sites: :environment do
      timed { Site.update_last_30_days_counters_for_not_archived_sites }
    end

    desc "Set first_billable_plays_at for all sites that already had more than 10 views / day"
    task set_first_billable_plays_at_for_not_archived_sites: :environment do
      timed { Site.set_first_billable_plays_at_for_not_archived_sites }
    end
  end

  namespace :stats do

    # desc "Split site_stats collection to separate minute/hour/day collection"
    # task split_site_stats_collection: :environment do
    #   timed do
    #     LegacyStat::Site.where(m: { '$ne' => nil }).all.each do |stat|
    #       attributes = stat.attributes.slice('t', 'pv', 'vv', 'md', 'bp')
    #       Stat::Site::Minute.create(attributes.merge(d: stat.m))
    #     end
    #     p "Split site minute stats"
    #   end
    #   timed do
    #     LegacyStat::Site.where(h: { '$ne' => nil }).all.each do |stat|
    #       attributes = stat.attributes.slice('t', 'pv', 'vv', 'md', 'bp')
    #       Stat::Site::Hour.create(attributes.merge(d: stat.h))
    #     end
    #     p "Split site hour stats"
    #   end
    #   timed do
    #     LegacyStat::Site.where(d: { '$ne' => nil }).all.each do |stat|
    #       attributes = stat.attributes.slice('t', 'pv', 'vv', 'md', 'bp')
    #       Stat::Site::Day.create(attributes.merge(d: stat.d))
    #     end
    #     p "Split site day stats"
    #   end
    # end
    #
    # desc "Split video_stats collection to separate minute/hour/day collection"
    # task split_video_stats_collection: :environment do
    #   timed do
    #     LegacyStat::Video.where(m: { '$ne' => nil }).all.each do |stat|
    #       attributes = stat.attributes.slice('st', 'u', 'vl', 'vv', 'md', 'bp', 'vs').merge('d' => stat.m)
    #       attributes['vlc'] = attributes['vl']['m'].to_i + attributes['vl']['e'].to_i
    #       attributes['vvc'] = attributes['vv']['m'].to_i + attributes['vv']['e'].to_i
    #       Stat::Video::Minute.create(attributes)
    #     end
    #     p "Split video minute stats"
    #   end
    #   timed do
    #     LegacyStat::Video.where(h: { '$ne' => nil }).all.each do |stat|
    #       attributes = stat.attributes.slice('st', 'u', 'vl', 'vv', 'md', 'bp', 'vs').merge('d' => stat.h)
    #       attributes['vlc'] = attributes['vl']['m'].to_i + attributes['vl']['e'].to_i
    #       attributes['vvc'] = attributes['vv']['m'].to_i + attributes['vv']['e'].to_i
    #       Stat::Video::Hour.create(attributes)
    #     end
    #     p "Split video hour stats"
    #   end
    #   timed do
    #     LegacyStat::Video.where(d: { '$ne' => nil }).all.each do |stat|
    #       attributes = stat.attributes.slice('st', 'u', 'vl', 'vv', 'md', 'bp', 'vs').merge('d' => stat.d)
    #       attributes['vlc'] = attributes['vl']['m'].to_i + attributes['vl']['e'].to_i
    #       attributes['vvc'] = attributes['vv']['m'].to_i + attributes['vv']['e'].to_i
    #       Stat::Video::Day.create(attributes)
    #     end
    #     p "Split video day stats"
    #   end
    # end

    # require 'zlib'
    # desc "Merge duplicate VideoStats and delete bad VideoTags based on wrong CRC32 generation (? params included)"
    # task merge_duplicate_video_stats_and_delete_bad_video_tags: :environment do
    #   timed do
    #     # Sites using video sources with ?
    #     site_tokens = [
    #       '2xrynuh2', 'lfmxr9gt', 'g39fmpp1', '1gt8yor7', '7k9odjzv', 'txohtl11', 'vfzh18bi', '2l7axk8c', 'iaruw1qi', 'avd44aef', 'nn8698ww',
    #       '4aeqofw0', 'nne3u3qd', 'h5qegk5j', 'op0mkqtn', 'suwutgs8', 'rrj45mbt', 'uvrkjs6y', '87r9xy5e', '0apmxu9m', 'bo6onvdp', 't1el7q92',
    #       'wtlrh4a1', '8pettr2l', 'ovjigy83', 'ipemdsdc', '8z30ym0w', '5ataduh2', 'mtrrhukx', 'wwaswim5', 'f5n04h63', '4md5tnvw', 'd4jhdmde',
    #       '29a31wy1', 'kaxf52ke', 'jag8liea', 'q87gxah0', 'alv676x0', 'b13hmic3', 'qn3ort3a', 'q7z31dji', 'pn1nfhuj', '7aph6o5g', '8hgvyvlc',
    #       'wsj6kezk', 'd8rjro54', '9pkh3pou', 'erfb5jxm', 'eq916p01', '7l6sr5hh', 'j9q1y3m1', '95ahxpcg', 'why96mtw', 'oqdmk4t6', 'xqnzpou9',
    #       'j0lqevol', 'lbshmaxk', 'lv9n9gdv', 'dsopijh8', 'fq1qtj48', '83y67ght', '8e7bgm4a', '3w98phzh', 'r7mul5tt', '2b4x0kwg', 'y7areitu',
    #       'o8ptoe09', 'ai42982g', 'oaiknkun', 'm0lzy3xt', 'quq4zs1k', 'ybjtuko4', 'gf2gv810', '0l5c6oby', 'ytxg2sy5', 'ykfg8c0a', 'j4nw7nem',
    #       'aoq66s9z', '7b8nn1v4', 'd67d4bn4', 'jpjr8p4d', '9majtpzr', 'mmvg0rfl', 'v8tqssb9', 'tbhdl70s', 'szejjut1', 'uo742m30', '2ir8o5ky',
    #       'ngyd2tdi', '3y0866sj', 'mur4c2aa', 'mkkaahxf', 'jv4dcx3o', '6j4zanab', 'jx5qyjz1', '55woyzoi', 'q43b92jx', '7gd9zazc', '6n6lb66i',
    #       'fj76pfnh', 'l45d3c3u', 'ikfqgbx0', 'kpcxti7e', '4ot5x0w2', 'ibvjcopp', 'pczql2wt', 'xwccapc5', '9cu26xxg', '4ptfsgbk', '0ljd7qrk',
    #       'mb27lban', '8vnlactg', 'rm8w0f9k', 'qdvuigm7', 'vwftwdte', 'estq9huv', 'ihuf4f5u', 'kq8zmtdf', 'uazs3te5', 'ql0355zz', 'y5uk4rpd',
    #       '6pdo240s', 'qeiwa7fu', 'qsr700iv'
    #     ]
    #     criteria = VideoTag.where(st: { '$in' => site_tokens }, uo: { '$ne' => 'a' }, created_at: { "$lte" => Time.utc(2012, 1, 19) })
    #     criteria.each do |video_tag|
    #       case video_tag.uo
    #       when 's'
    #         video_crc = video_tag.cs.first
    #         if video_tag.s[video_crc]
    #           video_source = video_tag.s[video_crc]['u']
    #         else
    #           video_crc, hash = video_tag.s.first
    #           video_source = hash['u']
    #         end
    #
    #         if video_source.include?('?')
    #           good_video_crc = Zlib.crc32(video_source.match(/^(.*)\?/)[1]).to_s(16)
    #           if good_video_crc != video_crc
    #             bad_video_stat_crit  = LegacyStat::Video.where(st: video_tag.st, u: video_crc)
    #             bad_video_stat_count = bad_video_stat_crit.count
    #             case bad_video_stat_count
    #             when 1
    #               bad_video_stat = bad_video_stat_crit.first
    #               if good_video_stat = LegacyStat::Video.where(st: video_tag.st, u: good_video_crc, d: bad_video_stat.d).first
    #                 merge_video_stat(bad_video_stat, good_video_stat)
    #                 bad_video_stat.delete
    #               else
    #                 update_bad_video_stat(bad_video_stat, good_video_crc)
    #               end
    #
    #               if VideoTag.where(st: video_tag.st, u: good_video_crc).exists?
    #                 video_tag.delete
    #               else
    #                 update_bad_video_tag(video_tag, good_video_crc)
    #               end
    #             when 0
    #               # nothing special to do
    #               video_tag.delete
    #             end
    #           end
    #         end
    #       else # nil
    #         bad_video_stat_crit = LegacyStat::Video.where(st: video_tag.st, u: video_tag.u)
    #         bad_video_stat_count = bad_video_stat_crit.count
    #         if bad_video_stat_count <= 1
    #           bad_video_stat_crit.delete
    #           video_tag.delete
    #         end
    #       end
    #     end
    #   end
    # end
  end

  # def merge_video_stat(bad_video_stat, good_video_stat)
  #   inc = {}
  #   bad_video_stat.bp.each { |k, v| inc["bp.#{k}"] = v }
  #   bad_video_stat.md.each { |k1, v| v.each { |k, v| inc["md.#{k1}.#{k}"] = v } }
  #   bad_video_stat.vl.each { |k, v| inc["vl.#{k}"] = v }
  #   bad_video_stat.vv.each { |k, v| inc["vv.#{k}"] = v }
  #   inc["vs.#{good_video_stat.u}"] = bad_video_stat.vs[bad_video_stat.u]
  #   LegacyStat::Video.collection.update({ st: good_video_stat.st, u: good_video_stat.u, d: good_video_stat.d.to_time }, { "$inc" => inc }, upsert: true)
  # end
  #
  # def update_bad_video_stat(bad_video_stat, good_video_crc)
  #   bad_video_stat.vs = { good_video_crc => bad_video_stat.vs[bad_video_stat.u] }
  #   bad_video_stat.u = good_video_crc
  #   bad_video_stat.save!
  # end
  #
  # def update_bad_video_tag(bad_video_tag, good_video_crc)
  #   if source = bad_video_tag.s[bad_video_tag.u]
  #     bad_video_tag.s = { good_video_crc => source }
  #   end
  #   bad_video_tag.cs = [good_video_crc]
  #   bad_video_tag.u = good_video_crc
  #   bad_video_tag.save!
  # end

end