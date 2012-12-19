# encoding: utf-8
require_dependency 'recurring_job'
require_dependency 'video_tag_trackers_parser'
require_dependency 'video_tag_updater'

class Log::Voxcast < ::Log
  field :stats_parsed_at,       type: DateTime
  field :referrers_parsed_at,   type: DateTime
  field :user_agents_parsed_at, type: DateTime
  field :video_tags_parsed_at,  type: DateTime

  attr_accessible :file

  # ================
  # = Associations =
  # ================

  has_many :usages, class_name: "SiteUsage", foreign_key: :log_id

  # ===============
  # = Validations =
  # ===============

  validates :file, presence: true

  # =================
  # = Class Methods =
  # =================

  def self.download_and_create_new_logs
    new_log_ended_at = nil
    while (new_log_ended_at = next_log_ended_at(new_log_ended_at)) < Time.now.utc do
      new_log_name = log_name(new_log_ended_at)
      with(safe: true).create!(
        name: new_log_name,
        file: CDN::VoxcastWrapper.download_log(new_log_name)
      )
    end
  end

  def self.log_name(ended_at)
    "#{CDN::VoxcastWrapper.hostname}.log.#{ended_at.to_i - 60}-#{ended_at.to_i}.gz"
  end

  def self.next_log_ended_at(last_log_ended_at = nil)
    last_ended_at = last_log_ended_at ||
      where(hostname: CDN::VoxcastWrapper.hostname, created_at: { :$gt => 7.day.ago }).order_by([:ended_at, :desc]).first.try(:ended_at) ||
      1.minute.ago.change(sec: 0)
    last_ended_at + 60.seconds
  end

  class << self
    %w[stats referrers user_agents video_tags].each do |type|
      define_method("parse_log_for_#{type}") do |id|
        log = find(id)
        unless log.send "#{type}_parsed_at?"
          log.send "parse_and_create_#{type}!"
          log.with(safe: true).update_attribute("#{type}_parsed_at", Time.now.utc)
        end
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Used in Log#parse_log
  def parse_and_create_usages!
    trackers = trackers(self.class.config[:file_format_class_name])
    SiteUsage.create_usages_from_trackers!(self, trackers)
  end

  def parse_and_create_stats!
    trackers = trackers('LogsFileFormat::VoxcastStats')
    Stat.create_stats_from_trackers!(self, trackers)
  end

  def parse_and_create_referrers!
    trackers = trackers('LogsFileFormat::VoxcastReferrers')
    Referrer.create_or_update_from_trackers!(trackers)
  end

  def parse_and_create_user_agents!
    trackers = trackers('LogsFileFormat::VoxcastUserAgents')
    UsrAgent.create_or_update_from_trackers!(self, trackers)
  end

  def parse_and_create_video_tags!
    video_tags_trackers  = trackers('LogsFileFormat::VoxcastVideoTags', title: :video_tags)
    video_tags_data = VideoTagTrackersParser.extract_video_tags_data(video_tags_trackers)
    video_tags_data.each do |(site_token, uid), data|
      data.each do |key, value|
        if value.is_a?(String)
          value.force_encoding('binary')
          data[key] = value.encode('utf-8', :invalid => :replace, :undef => :replace)
        end
      end
      VideoTagUpdater.delay.update(site_token, uid, data)
    end
  end

  def minute
    @minute ||= started_at.change(sec: 0, usec: 0).to_time
  end

  def hour
    started_at.change(min: 0, sec: 0, usec: 0).to_time
  end

private

  # after_create on log model
  def delay_parse
    self.class.delay(queue: 'log_high', at: 5.seconds.from_now.to_i).parse_log_for_stats(id)
    self.class.delay(queue: 'log_high', at: 5.seconds.from_now.to_i).parse_log_for_video_tags(id)
    self.class.delay(queue: 'log', at: 10.seconds.from_now.to_i).parse_log(id)
    self.class.delay(queue: 'log', at: 10.seconds.from_now.to_i).parse_log_for_user_agents(id)
    self.class.delay(queue: 'log', at: 10.seconds.from_now.to_i).parse_log_for_referrers(id)
  end

  # call from name= in Log
  def set_dates_and_hostname_from_name
    if matches = name.match(/^(.+)\.log\.(\d+)-(\d+)\.\w+$/)
      self.hostname   ||= matches[1]
      self.started_at ||= Time.at(matches[2].to_i).utc
      self.ended_at   ||= Time.at(matches[3].to_i).utc
    end
  end

end
