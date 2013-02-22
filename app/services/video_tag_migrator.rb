require 'video_tag_updater_worker'

class VideoTagMigrator
  attr_reader :video_tag

  def initialize(video_tag)
    @video_tag = video_tag
  end

  def migrate
    if uid_from_attribute? || real_stats?
      delay_migration
    else
      video_tag.destroy
      stats.delete_all
    end
  end

  private

  def delay_migration
    VideoTagUpdaterWorker.perform_async(video_tag.site.token, video_tag.uid, converted_data)
  end

  def stats
    Stat::Video::Day.where(st: video_tag.site.token, u: video_tag.uid)
  end

  def real_stats?
    stats.count > 1 || (stats.first && stats.first.d > 1.week.ago)
  end

  def converted_data
    {}.tap do |h|
      h[:uo] = video_tag.uid_origin.first
      h[:t]  = video_tag.name if name_from_attribute?
      h[:p]  = video_tag.poster_url
      h[:p]  = video_tag.poster_url
      h[:d]  = video_tag.duration
      h[:z]  = video_tag.size
      if video_tag.sources_origin == 'youtube'
        h[:i]  = video_tag.sources_id
        h[:io] = 'y'
      else
        h[:s]  = converted_sources
      end
      h[:created_at] = video_tag.created_at
      h[:updated_at] = video_tag.updated_at
    end
  end

  def converted_sources
    video_tag.used_sources.map do |source|
      {
        u: source[1][:url],
        f: source[1][:family],
        q: source[1][:quality],
        r: source[1][:resolution]
      }
    end
  end

  def name_from_attribute?
    video_tag.name_origin == 'attribute'
  end

  def uid_from_attribute?
    video_tag.uid_origin == 'attribute'
  end

end
