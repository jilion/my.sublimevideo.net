class VideoTag < ActiveRecord::Base
  serialize :current_sources, Array
  serialize :sources, Hash
  serialize :settings, ActiveRecord::Coders::Hstore

  belongs_to :site

  # scope :custom_search, lambda { |query|
  #   where(:$or => [
  #     { n: /.*#{query}.*/i },
  #     { u: /.*#{query}.*/i }
  #   ])
  # }

  # filter
  scope :last_30_days_active, -> { where{ updated_at >= 30.days.ago.midnight } }
  scope :last_90_days_active, -> { where{ updated_at >= 90.days.ago.midnight } }
  # scope :hosted_on_sublimevideo, where({}) # TODO Thibaud
  # scope :not_hosted_on_sublimevideo, where({}) # TODO Thibaud
  # scope :inactive, where(state: 'inactive')
  scope :active, -> { where{ (uid_origin != nil) & (name_origin != nil)} }
  # scope :all, where({}) # TODO Thibaud

  # sort
  scope :by_name,  lambda { |way = 'desc'| order{ name.send(way) } }
  scope :by_date,  lambda { |way = 'desc'| order{ created_at.send(way) } }
  # scope :by_state, lambda { |way='desc'| order_by([:state, way.to_sym]) }

  validates :site_id, presence: true, uniqueness: { scope: :uid }
  validates :site_token, presence: true
  validates :uid, :uid_origin, presence: true
  validates :uid_origin, inclusion: %w[attribute source]
  validates :name_origin, inclusion: %w[attribute source youtube vimeo], allow_nil: true
  validates :sources_origin, inclusion: %w[youtube vimeo other], allow_nil: true

  def to_param
    uid
  end

  def uid=(attribute)
    write_attribute :uid, attribute.to_s.try(:to, 254)
  end

  def name=(attribute)
    write_attribute :name, attribute.to_s.try(:to, 254)
  end

  def duration=(attribute)
    duration = attribute.to_i > 2147483647 ? 2147483647 : attribute.to_i
    write_attribute :duration, duration
  end

  def sources=(attributes)
    attributes.each do |crc32, source_data|
      unless sources[crc32] == source_data
        sources_will_change!
        sources[crc32] = source_data
      end
    end
    write_attribute :sources, sources
  end

  # TODO Remove once VideoTag data only get from CORS
  def used_sources
    sources.select { |key, value| key.in?(current_sources) }
  end

  def backbone_data
    attributes.slice(*%w[uid uid_origin name name_origin poster_url sources_id sources_origin])
  end
end

# == Schema Information
#
# Table name: video_tags
#
#  created_at      :datetime         not null
#  current_sources :text
#  duration        :integer
#  id              :integer          not null, primary key
#  name            :string(255)
#  name_origin     :string(255)
#  poster_url      :text
#  settings        :hstore
#  site_id         :integer          not null
#  site_token      :string(255)      not null
#  size            :string(255)
#  sources         :text
#  sources_id      :string(255)
#  sources_origin  :string(255)
#  uid             :string(255)      not null
#  uid_origin      :string(255)      not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_video_tags_on_site_id_and_uid         (site_id,uid) UNIQUE
#  index_video_tags_on_site_id_and_updated_at  (site_id,updated_at)
#

