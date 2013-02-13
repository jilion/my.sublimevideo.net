class UsrAgent # fucking name conflict with UserAgent gem
  include Mongoid::Document

  field :token
  field :month,     type: DateTime

  field :platforms, type: Hash # { "iPad" => { "iOS 3.2" => 32, "iOS 4.2" => 31, "Unknown" => 12 }, "Unknown" => 123 }
  field :browsers,  type: Hash # { "Safari" => { "versions" => { "4.0.4" => 123, "5.0" => 12, "Unknown" => 123 }, "platforms" => { "iPad" => 12, "Windows" => 12, "Unknown" => 123 } }, "Unknown" => 123 }

  index month: 1, token: 1 # UsrAgent#create_or_update_from_trackers

  attr_accessible :token, :platforms, :browsers, :month

  # ================
  # = Associations =
  # ================

  def site
    Site.find_by_token(token)
  end

  # ===============
  # = Validations =
  # ===============

  validates :token, presence: true
  validates :month, presence: true

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(log, trackers)
    incs = incs_from_trackers(trackers)
    incs.each do |token, inc|
      self.collection
        .find(token: token, month: log.month)
        .update({ :$inc => inc }, upsert: true)
    end
  end

private

  def self.incs_from_trackers(trackers)
    trackers = trackers.detect { |t| t.options[:title] == :useragent }.categories
    incs     = Hash.new { |h,k| h[k] = Hash.new(0) }
    trackers.each do |tracker, hits|
      useragent_string, token = tracker
      if useragent_hash = useragent_hash(useragent_string)
        incs[token]["platforms.#{useragent_hash[:platform]}.#{useragent_hash[:os]}"] += hits
        incs[token]["browsers.#{useragent_hash[:browser]}.versions.#{useragent_hash[:version]}"] += hits
        incs[token]["browsers.#{useragent_hash[:browser]}.platforms.#{useragent_hash[:platform]}"] += hits
      end
    end
    incs
  end

  def self.useragent_hash(useragent_string)
    return false if useragent_string.blank?
    begin
      useragent = UserAgent.parse(useragent_string) # gem here
    rescue => ex
      Notifier.send("UserAgent (gem) parsing problem with: #{useragent_string}", exception: ex)
    end
    if useragent.present?
      hash = %w[browser version platform os].inject({}) do |hash, attr|
        hash[attr.to_sym] = useragent.send(attr).try(:gsub, /\./, '::') || "unknown"
        hash
      end
      if hash[:browser] == "unknown" || hash[:version] == "unknown"
        unknowns = hash.select { |k, v| v == "unknown" }.keys
        unless UsrAgentUnknown.where(user_agent: useragent_string).exists?
          UsrAgentUnknown.create(user_agent: useragent_string, unknowns: unknowns)
        end
      end
      hash
    end
  end

end
