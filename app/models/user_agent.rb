class UserAgent
  include Mongoid::Document

  field :site_id,         :type => Integer
  field :token
  field :month,           :type => DateTime

  field :platforms,        :type => Hash # { "iPad" => { "iOS 3.2" => 32, "iOS 4.2" => 31, "Unknown" => 12 }, "Unknown" => 123 }
  field :browsers,         :type => Hash # { "Safari" => { "versions" => { "4.0.4" => 123, "5.0" => 12, "Unknown" => 123 }, "platforms" => { "iPad" => 12, "Windows" => 12, "Unknown" => 123 } }, "Unknown" => 123 }

  index :site_id
  index :token
  index :month

  attr_accessible :token, :platforms, :browsers, :month

  # Pagination
  cattr_accessor :per_page
  self.per_page = 100

  # ================
  # = Associations =
  # ================

  def site
    Site.find_by_id(site_id)
  end
  def token=(token)
    write_attribute(:site_id, Site.find_by_token(token).try(:id))
  end

  # ===============
  # = Validations =
  # ===============

  validates :site_id, :presence => true
  validates :token,   :presence => true
  validates :month,   :presence => true

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(log, trackers)
    ref_hash = trackers.detect { |t| t.options[:title] == :useragent }.categories
    ref_hash.each do |useragent_and_token, hits|
      puts useragent_and_token
      useragent_str, token = useragent_and_token[0],  useragent_and_token[1]
      puts useragent_str
      puts token
      user_agent_info = UserAgentGem.parse(useragent_str)
      puts user_agent_info.browser
      puts user_agent_info.version
      puts user_agent_info.platform
      puts user_agent_info.os
      month = log.started_at.utc.to_time.beginning_of_month
      puts month
      # if useragent = UserAgent.where(:month => month, :token => token).first
      #   # referrer.hits = referrer.hits.to_i + hits
      #   # referrer.save
      # else
      #   create(
      #     :month => month,
      #     :token => token
      #   )
      # end
    end
  end

end
