require 'searchable'

class Enthusiast < ActiveRecord::Base
  include Searchable

  attr_accessible :email, :free_text, :interested_in_beta, :sites_attributes, :remote_ip, :starred, :invited_at

  has_one :user

  has_many :sites, class_name: 'EnthusiastSite', dependent: :destroy
  accepts_nested_attributes_for :sites, reject_if: ->(site) { site[:hostname].blank? }, allow_destroy: true

  default_scope where(trashed_at: nil)

  scope :starred,                -> { where { starred == true } }
  scope :confirmed,              -> { where { confirmed_at != nil } }
  scope :not_confirmed,          -> { where { confirmed_at == nil } }
  scope :invited,                -> { where { invited_at != nil } }
  scope :not_invited,            -> { where { invited_at == nil } }
  scope :interested_in_beta,     -> { where { interested_in_beta == true } }
  scope :not_interested_in_beta, -> { where { interested_in_beta == false } }
  scope :not_already_resent_confirmation_instructions, -> { where { confirmation_resent_at == nil } }

  scope :having_comment, ->(bool) { bool ? where { free_text << ['', nil] } : where { free_text >> ['', nil] } }
  scope :having_site,    ->(bool) { bool ? select('DISTINCT(enthusiasts.id)').joins(:sites) : where('enthusiasts.id NOT IN (?)', having_site(true)) }

  scope :by_date,               ->(way = 'desc') { order { created_at.send(way) } }
  scope :by_email,              ->(way = 'desc') { order { email.send(way) }.order { created_at.desc } }
  scope :by_starred,            ->(way = 'asc') { order { starred.send(way) }.order { created_at.desc } }
  scope :by_confirmed,          ->(way = 'asc') { order { confirmed_at.send(way) }.order { created_at.desc } }
  scope :by_interested_in_beta, ->(way = 'desc') { order { interested_in_beta.send(way) }.order { created_at.desc } }
  scope :by_invited,            ->(way = 'desc') { order { invited_at.send(way) }.order { created_at.desc } }

  def self.additional_or_conditions
    %w[email free_text].reduce([]) { |a, e| a << ("lower(#{e}) =~ " + 'lower("%#{q}%")') }
  end

  def confirmation_resent?
    confirmation_resent_at?
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

