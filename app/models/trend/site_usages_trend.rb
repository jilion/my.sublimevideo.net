class SiteUsagesTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :lh, type: Hash,    default: {} # Loader hits: { ns (non-ssl) => 2, s (ssl) => 1 }
  field :ph, type: Hash,    default: {} # Player hits: { m (main non-cached) => 3, mc (main cached) => 1, e (extra non-cached) => 3, ec (extra cached) => 1, d (dev non-cached) => 3, dc (dev cached) => 1, i (invalid non-cached) => 3, ic (invalid cached) => 1 }
  field :fh, type: Integer, default: 0  # Flash hits
  field :sr, type: Integer, default: 0  # S3 Requests
  field :tr, type: Hash,    default: {} # Traffic (bytes): { s (s3) => 2123, v (voxcast) => 1231 }

  def self.json_fields
    [:lh, :ph, :fh, :sr, :tr]
  end
end
