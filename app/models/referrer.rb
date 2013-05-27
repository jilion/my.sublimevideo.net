class Referrer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token
  field :url
  field :hits,            type: Integer, default: 0

  index token: 1, url: 1
  index hits: 1
  index updated_at: 1

  attr_accessible :token, :url, :hits

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

  scope :with_tokens,        ->(tokens) { where(:token.in => tokens.map(&:to_i)) }
  scope :by_hits,            ->(way = 'desc') { order_by([:hits, way.to_sym]) }
  scope :by_updated_at,      ->(way = 'desc') { order_by([:updated_at, way.to_sym]) }

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(trackers)
    ref_hash = trackers.find { |t| t.options[:title] == :referrers }.categories
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
end
