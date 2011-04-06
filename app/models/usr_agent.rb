class UsrAgent # fucking name conflict with UserAgent gem
  include Mongoid::Document

  field :site_id,         :type => Integer
  field :token
  field :month,           :type => DateTime

  field :platforms,       :type => Hash, :default => {} # { "iPad" => { "iOS 3.2" => 32, "iOS 4.2" => 31, "Unknown" => 12 }, "Unknown" => 123 }
  field :browsers,        :type => Hash, :default => {} # { "Safari" => { "versions" => { "4.0.4" => 123, "5.0" => 12, "Unknown" => 123 }, "platforms" => { "iPad" => 12, "Windows" => 12, "Unknown" => 123 } }, "Unknown" => 123 }

  index :site_id
  index :token
  index :month

  attr_accessible :token, :platforms, :browsers, :month

  # ================
  # = Associations =
  # ================

  def site
    Site.find_by_id(site_id)
  end
  def token=(token)
    write_attribute(:token, token)
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
      useragent_string, token = useragent_and_token[0],  useragent_and_token[1]
      if useragent_string.present?
        if useragent_hash = useragent_hash(useragent_string)
          month = log.started_at.beginning_of_month
          if usr_agent = UsrAgent.where(:month => month, :token => token).first
            usr_agent.update_hashes(hits, useragent_hash)
          else
            self.create(
              :month     => month,
              :token     => token,
              :platforms => { useragent_hash[:platform] => { useragent_hash[:os] => hits } },
              :browsers  => { useragent_hash[:browser]  => { "versions" => { useragent_hash[:version] => hits }, "platforms" => { useragent_hash[:platform] => hits } } }
            )
          end
        end
      end
    end
  end

private

  def self.useragent_hash(useragent_string)
    begin
      useragent = UserAgent.parse(useragent_string) # gem here
    rescue => ex
      Notify.send("UserAgent (gem) parsing problem with: #{useragent_string}", :exception => ex)
    end
    if useragent.present?
      hash = %w[browser version platform os].inject({}) do |hash, attr|
        hash[attr.to_sym] = useragent.send(attr).try(:gsub,/\./, '::') || "unknown"
        hash
      end
      if hash[:browser] == "unknown" || hash[:version] == "unknown"
        unknowns = hash.select { |k, v| v == "unknown" }.keys
        unless UsrAgentUnknown.where(:user_agent => useragent_string).exists?
          UsrAgentUnknown.create(:user_agent => useragent_string, :unknowns => unknowns )
        end
      end
      hash
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

public

  def update_hashes(hits, useragent_hash={})
    # platforms
    platforms_dup = self[:platforms].dup
    platforms_dup[useragent_hash[:platform]] ||= {}
    platforms_dup[useragent_hash[:platform]][useragent_hash[:os]] = platforms_dup[useragent_hash[:platform]][useragent_hash[:os]].to_i + hits
    self.platforms = {} # force dirty attribute https://github.com/mongoid/mongoid/issues/issue/323
    self.platforms = platforms_dup
    # browsers
    browsers_dup = self[:browsers].dup
    browsers_dup[useragent_hash[:browser]] ||= { "versions" => {}, "platforms" => {} }
    browsers_dup[useragent_hash[:browser]]["versions"][useragent_hash[:version]] = browsers_dup[useragent_hash[:browser]]["versions"][useragent_hash[:version]].to_i + hits
    browsers_dup[useragent_hash[:browser]]["platforms"][useragent_hash[:platform]] = browsers_dup[useragent_hash[:browser]]["platforms"][useragent_hash[:platform]].to_i + hits
    self.browsers = {} # force dirty attribute https://github.com/mongoid/mongoid/issues/issue/323
    self.browsers = browsers_dup
    self.save
  end

end
