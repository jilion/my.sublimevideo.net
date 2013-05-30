# encoding: utf-8
require 'thread'

class Log::Voxcast < ::Log
  field :stats_parsed_at,       type: DateTime
  field :referrers_parsed_at,   type: DateTime
  field :user_agents_parsed_at, type: DateTime
  field :video_tags_parsed_at,  type: DateTime

  attr_accessible :file

  # ===============
  # = Validations =
  # ===============

  validates :file, presence: true

  # =============
  # = Callbacks =
  # =============

  after_create :delay_parse

  # =================
  # = Class Methods =
  # =================

  def self.download_and_create_new_logs
    mutex.synchronize do
      new_ended_at = next_ended_at
      while new_ended_at < Time.now.utc
        new_name = log_filename(new_ended_at)
        log_file = VoxcastWrapper.download_log(new_name)
        with(safe: true).create(
          name: new_name,
          file: log_file
        )
        new_ended_at += 60.seconds
      end
    end
  end

  def self.mutex
    @mutex ||= Mutex.new
  end

  def self.log_filename(ended_at)
    "#{VoxcastWrapper.hostname}.log.#{ended_at.to_i - 60}-#{ended_at.to_i}.gz"
  end

  def self.next_ended_at
    (where(hostname: VoxcastWrapper.hostname, created_at: { :$gt => 7.day.ago }).order_by([:ended_at, :desc]).first.try(:ended_at) ||
      1.minute.ago.change(sec: 0)) + 60.seconds
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

  def parse_and_create_stats!
    trackers = trackers('VoxcastStatsLogFileFormat')
    Stat.create_stats_from_trackers!(self, trackers)
  end

  def parse_and_create_referrers!
    trackers = trackers('VoxcastReferrersLogFileFormat')
    Referrer.create_or_update_from_trackers!(trackers)
  end

  def parse_and_create_user_agents!
    trackers = trackers('VoxcastUserAgentsLogFileFormat')
    UsrAgent.create_or_update_from_trackers!(self, trackers)
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
