class RecurringStatsPopulator < StatsPopulator

  def execute(site)
    PopulateHelpers.empty_tables(Stat::Site::Day, Stat::Site::Hour, Stat::Site::Minute, Stat::Site::Second)
    video_tag_uids = %w[uid1 uid2 uid3]

    last_second  = 0
    videos_count = 20
    EM.run do
      EM.add_periodic_timer(0.001) do
        second = Time.now.change(usec: 0).to_time
        if last_second != second.to_i
          sleep rand(1)
          last_second = second.to_i
          EM.defer do
            video_tag_uids.each do |video_uid|
              if rand(10) >= 8
                # hits = rand(10) #second.to_i%10
                inc = random_site_stats_inc(60)
                Stat::Site::Second.collection.find(t: site.token, d: second).update({ :$inc => inc }, upsert: true)
                Stat::Video::Second.collection.find(st: site.token, d: second).update({ :$inc => inc }, upsert: true)
                # json = {
                #   site: { id: second.to_i, vv: hits },
                #   videos: [
                #     { id: second.to_i, u: video_uid, n: "Video #{video_i}", vv: hits }
                #   ]
                # }
                # Pusher.trigger_async("private-#{site.token}", 'stats', json)
                second = Time.now.change(usec: 0).to_time
                json = { "pv" => 1, "bp" => { "saf-osx" => 1 } }
                Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
                json = { "md" => { "f" => { "d" => 1 }, "h" => { "d" => 1 } } }
                Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
                json = { "vv" => 1 }
                Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
              end
            end
            puts "Stats updated at #{second}"
          end
        end
      end
    end

    # generate_seconds_stats(site)
    # generate_other_stats(site)
    # trig_pusher(site)
  end

  private

  def generate_seconds_stats(site)
    Thread.new do
      loop do
        second = Time.now.utc.change(usec: 0).to_time
        Stat::Site::Second.collection.find(t: site.token, d: second).update({ :$inc => random_site_stats_inc(1) }, upsert: true)
        sleep 1
      end
    end
  end

  def generate_other_stats(site)
    Thread.new do
      loop do
        now = Time.now.utc
        if now.change(usec: 0) == now.change(sec: 0, usec: 0)
          inc = random_site_stats_inc(60)
          Stat::Site::Minute.collection
            .find(t: site.token, d: (now - 1.minute).change(sec: 0, usec: 0).to_time)
            .update({ :$inc => inc }, upsert: true)
          Stat::Site::Hour.collection
            .find(t: site.token, d: (now - 1.minute).change(min: 0, sec: 0, usec: 0).to_time)
            .update({ :$inc => inc }, upsert: true)
          Stat::Site::Day.collection
            .find(t: site.token, d: (now - 1.minute).change(hour: 0, min: 0, sec: 0, usec: 0).to_time)
            .update({ :$inc => inc }, upsert: true)

          json = {}
          json[:h] = true if now.change(sec: 0, usec: 0) == now.change(min: 0, sec: 0, usec: 0)
          json[:d] = true if now.change(min: 0, sec: 0, usec: 0) == now.change(hour: 0, min: 0, sec: 0, usec: 0)
          Pusher.trigger('stats', 'tick', json)

          puts "Site(s) stats updated at #{now.change(sec: 0, usec: 0)}"
          sleep 50
        end
        sleep 0.9
      end
    end
  end

  def trig_pusher(site)
    EM.run do
      EM.add_periodic_timer(1) do
        EM.defer do
          second = Time.now.change(usec: 0).to_time
          json = { "pv" => 1, "bp" => { "saf-osx" => 1 } }
          Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
          json = { "md" => { "f" => { "d" => 1 }, "h" => { "d" => 1 } } }
          Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
          json = { "vv" => 1 }
          Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
        end
      end
    end
  end

end
