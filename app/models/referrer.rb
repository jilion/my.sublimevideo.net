class Referrer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :site_id,         :type => Integer
  field :token
  field :url
  field :hits,            :type => Integer
  field :contextual_hits, :type => Integer

  index :site_id
  index :token
  index :url
  index :hits
  index :contextual_hits
  index :created_at

  attr_accessible :token, :url, :hits, :contextual_hits

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
    write_attribute(:token, token)
    write_attribute(:site_id, Site.find_by_token(token).try(:id))
  end

  # ==========
  # = Scopes =
  # ==========

  scope :by_url,             lambda { |way = 'desc'| order_by([:url, way.to_sym]) }
  scope :by_hits,            lambda { |way = 'desc'| order_by([:hits, way.to_sym]) }
  scope :by_contextual_hits, lambda { |way = 'desc'| order_by([:contextual_hits, way.to_sym]) }
  scope :by_updated_at,      lambda { |way = 'desc'| order_by([:updated_at, way.to_sym]) }
  scope :by_created_at,      lambda { |way = 'desc'| order_by([:created_at, way.to_sym]) }

  # ===============
  # = Validations =
  # ===============

  validates :token,   :presence => true
  validates :site_id, :presence => true
  validates :url,     :presence => true, :format => { :with => /^http\:\/\/.*/ }

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(trackers)
    ref_hash = trackers.detect { |t| t.options[:title] == :referrers }.categories
    ref_hash.each do |url_and_token, hits|
      url, token = url_and_token[0],  url_and_token[1]
      if referrer = Referrer.where(:url => url, :token => token).first
        referrer.hits.to_i += hits
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
        referrer.contextual_hits.to_i += 1 if type == 'c'
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