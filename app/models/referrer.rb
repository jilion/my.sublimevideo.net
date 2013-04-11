class Referrer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token
  field :url
  field :hits,            type: Integer, default: 0
  field :badge_hits,      type: Integer, default: 0
  field :contextual_hits, type: Integer, default: 0

  index token: 1, url: 1
  index hits: 1
  index badge_hits: 1
  index contextual_hits: 1
  index created_at: 1
  index updated_at: 1

  attr_accessible :token, :url, :hits, :contextual_hits, :badge_hits

  cattr_accessor :per_page
  self.per_page = 100

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
  validates :url,   presence: true, format: { with: /^https?\:\/\/.*/ }

  # ==========
  # = Scopes =
  # ==========

  scope :with_tokens,        ->(tokens) { where(token: tokens) }
  scope :by_url,             ->(way = 'desc') { order_by([:url, way.to_sym]) }
  scope :by_hits,            ->(way = 'desc') { order_by([:hits, way.to_sym]) }
  scope :by_badge_hits,      ->(way = 'desc') { order_by([:badge_hits, way.to_sym]) }
  scope :by_contextual_hits, ->(way = 'desc') { order_by([:contextual_hits, way.to_sym]) }
  scope :by_updated_at,      ->(way = 'desc') { order_by([:updated_at, way.to_sym]) }
  scope :by_created_at,      ->(way = 'desc') { order_by([:created_at, way.to_sym]) }

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(trackers)
    ref_hash = trackers.detect { |t| t.options[:title] == :referrers }.categories
    ref_hash.each do |url_and_token, hits|
      url, token = url_and_token[0],  url_and_token[1]
      if referrer = Referrer.where(url: url, token: token).first
        referrer.hits += hits
        referrer.save
      else
        create(url: url, token: token, hits: hits)
      end
    end
  end

  def self.create_or_update_from_type(token, url, type = 'c')
    if referrer = Referrer.where(url: url, token: token).first
      case type
      when 'b'
        referrer.badge_hits += 1
      when 'c'
        referrer.contextual_hits += 1
      end
      referrer.save
    else
      create(
        url:             url,
        token:           token,
        badge_hits:      (type == 'b' ? 1 : 0),
        contextual_hits: (type == 'c' ? 1 : 0)
      )
    end
  end

end
