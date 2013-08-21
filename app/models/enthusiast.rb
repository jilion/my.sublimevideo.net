require 'searchable'

class Enthusiast < ActiveRecord::Base
  include Searchable

  attr_accessible :email, :free_text, :interested_in_beta, :sites_attributes, :remote_ip, :starred, :invited_at

  has_one :user

  has_many :sites, class_name: 'EnthusiastSite', dependent: :destroy
  accepts_nested_attributes_for :sites, reject_if: ->(site) { site[:hostname].blank? }, allow_destroy: true

  default_scope { where(trashed_at: nil) }

  %w[email created_at invited_at].each do |col|
    scope :"by_#{col}", ->(way = 'desc') { order("#{col} #{way}").order('created_at desc') }
  end

  def self.additional_or_conditions(q)
    lower_and_match_fields(%w[email free_text])
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

