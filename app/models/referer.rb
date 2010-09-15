class Referer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :site_id, :type => Integer
  field :token
  field :url
  field :hits,    :type => Integer
  
  index :site_id
  index :token
  index :url
  index :created_at
  
  attr_accessible :token, :url, :hits
  
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
  
  validates :token,  :presence => true, :on => :create
  validates :url,    :presence => true
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_or_update_from_trackers!(trackers)
    ref_hash = trackers.detect { |t| t.options[:title] == :referers }.categories
    ref_hash.each do |url_and_token, hits|
      url, token = url_and_token[0],  url_and_token[1]
      if referer = Referer.where(:url => url, :token => token).first
        referer.hits += hits
        referer.save
      else
        create(
          :url   => url,
          :token => token,
          :hits  => hits
        )
      end
    end
  end
end