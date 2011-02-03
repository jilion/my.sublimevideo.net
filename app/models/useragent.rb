class Useragent
  include Mongoid::Document
  
  field :site_id,         :type => Integer
  field :month,           :type => DateTime
  
  field :platforms,        :type => Hash # { "iPad" => { "iOS 3.2" => 32, "iOS 4.2" => 31, "Unknown" => 12 }, "Unknown" => 123 }
  field :browsers,         :type => Hash # { "Safari" => { "versions" => { "4.0.4" => 123, "5.0" => 12, "Unknown" => 123 }, "platforms" => { "iPad" => 12, "Windows" => 12, "Unknown" => 123 } }, "Unknown" => 123 }

  index :site_id
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
  validates :month,   :presence => true

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(trackers)
    ref_hash = trackers.detect { |t| t.options[:title] == :referrers }.categories
    ref_hash.each do |url_and_token, hits|
      url, token = url_and_token[0],  url_and_token[1]
      if referrer = Referrer.where(:url => url, :token => token).first
        referrer.hits = referrer.hits.to_i + hits
        referrer.save
      else
        create(
          :url   => url,
          :token => token,
          :hits  => hits
        )
      end
    end
  end

  def self.create_or_update_from_type!(token, url, type = 'c')
      if referrer = Referrer.where(:url => url, :token => token).first
        referrer.contextual_hits = referrer.contextual_hits.to_i + 1 if type == 'c'
        referrer.save
      else
        create(
          :url             => url,
          :token           => token,
          :contextual_hits => type == 'c' ? 1 : 0
        )
      end
  end

end