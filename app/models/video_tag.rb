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
  scope :active, -> { where{(uid_origin != nil) & (name_origin != nil)} }
  # scope :all, where({}) # TODO Thibaud

  # sort
  scope :by_name,  lambda { |way = 'desc'| order{ name.send(way) } }
  scope :by_date,  lambda { |way = 'desc'| order{ created_at.send(way) } }
  # scope :by_state, lambda { |way='desc'| order_by([:state, way.to_sym]) }

  validates :site_id, presence: true, uniqueness: { scope: :uid }
  validates :uid, :uid_origin, presence: true
  validates :uid_origin, :name_origin, inclusion: %w[attribute source]

  def to_param
    uid
  end

  # TODO Try to remove once passed to sidekiq
  def uid=(attribute)
    write_attribute :uid, attribute.try(:to, 254)
  end

  def name=(attribute)
    write_attribute :name, attribute.try(:to, 254)
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

  def data
    attributes.except(*%w[id created_at updated_at])
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
#  size            :string(255)
#  sources         :text
#  uid             :string(255)      not null
#  uid_origin      :string(255)      not null
#  updated_at      :datetime         not null
#  video_id        :string(255)
#  video_id_origin :string(255)
#
# Indexes
#
#  index_video_tags_on_site_id_and_uid         (site_id,uid) UNIQUE
#  index_video_tags_on_site_id_and_updated_at  (site_id,updated_at)
#

