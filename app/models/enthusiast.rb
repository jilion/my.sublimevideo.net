require 'searchable'

class Enthusiast < ActiveRecord::Base
  include Searchable

  attr_accessible :email, :free_text, :interested_in_beta, :sites_attributes, :remote_ip, :starred, :invited_at

  has_one :user

  has_many :sites, class_name: 'EnthusiastSite', dependent: :destroy
  accepts_nested_attributes_for :sites, reject_if: ->(site) { site[:hostname].blank? }, allow_destroy: true

  default_scope where(trashed_at: nil)

  scope :by_date,    ->(way = 'desc') { order { created_at.send(way) } }
  scope :by_email,   ->(way = 'desc') { order { email.send(way) }.order { created_at.desc } }
  scope :by_invited, ->(way = 'desc') { order { invited_at.send(way) }.order { created_at.desc } }

  def self.additional_or_conditions
    %w[email free_text].reduce([]) { |a, e| a << ("lower(#{e}) =~ " + 'lower("%#{q}%")') }
  end

  def confirmed?
    confirmed_at?
  end

protected

  def password_required?
    false
  end

end

# == Schema Information
#
# Table name: enthusiasts
#
#  confirmation_resent_at :datetime
#  confirmation_sent_at   :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  created_at             :datetime
#  email                  :string(255)
#  free_text              :text
#  id                     :integer          not null, primary key
#  interested_in_beta     :boolean
#  invited_at             :datetime
#  remote_ip              :string(255)
#  starred                :boolean
#  trashed_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_enthusiasts_on_email  (email) UNIQUE
#

