require 'core_ext/hash/join_keys'

class VideoStatsMerger
  attr_reader :site_token, :uid, :old_uid

  def initialize(site_token, uid, old_uid)
    @site_token = site_token
    @uid        = uid
    @old_uid    = old_uid
  end

  def merge!
    old_day_stats.each do |old_stat|
      merge_stat(old_stat)
      old_stat.destroy
    end
  end

  private

  def old_day_stats
    Stat::Video::Day.where(st: site_token, u: old_uid)
  end

  def merge_stat(stat)
    inc = inc_from_attributes(stat)
    Stat::Video::Day.collection
      .find(st: stat.st, u: uid, d: stat.d.to_time)
      .update({ :$inc => inc }, upsert: true)
  end

  def inc_from_attributes(stat)
    attributes_to_merge = stat.attributes.except(*%w[_id st u d])
    attributes_to_merge.join_keys
  end
end
