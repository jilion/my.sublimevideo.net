class Enthusiast < ActiveRecord::Base

  cattr_accessor :per_page
  self.per_page = 100

  attr_accessible :email, :free_text, :interested_in_beta, :sites_attributes, :remote_ip, :starred, :invited_at

  # ================
  # = Associations =
  # ================

  has_one :user

  has_many :sites, class_name: "EnthusiastSite", dependent: :destroy
  accepts_nested_attributes_for :sites, reject_if: lambda { |s| s[:hostname].blank? }, allow_destroy: true

  # ==========
  # = Scopes =
  # ==========

  default_scope where(trashed_at: nil)

  scope :starred,                where { starred == true }
  scope :confirmed,              where { confirmed_at != nil }
  scope :not_confirmed,          where { confirmed_at == nil }
  scope :invited,                where { invited_at != nil }
  scope :not_invited,            where { invited_at == nil }
  scope :interested_in_beta,     where { interested_in_beta == true }
  scope :not_interested_in_beta, where { interested_in_beta == false }
  scope :not_already_resent_confirmation_instructions, where { confirmation_resent_at == nil }

  scope :having_comment, lambda { |bool| bool ? where { free_text << ['', nil] } : where { free_text >> ['', nil] } }
  scope :having_site,    lambda { |bool| bool ? select("DISTINCT(enthusiasts.id)").joins(:sites) : where("enthusiasts.id NOT IN (?)", having_site(true)) }

  scope :by_date,               lambda { |way = 'desc'| order(:created_at.send(way)) }
  scope :by_email,              lambda { |way = 'desc'| order(:email.send(way), :created_at.desc) }
  scope :by_starred,            lambda { |way = 'asc'| order(:starred.send(way), :created_at.desc) }
  scope :by_confirmed,          lambda { |way = 'asc'| order(:confirmed_at.send(way), :created_at.desc) }
  scope :by_interested_in_beta, lambda { |way = 'desc'| order(:interested_in_beta.send(way), :created_at.desc) }
  scope :by_invited,            lambda { |way = 'desc'| order(:invited_at.send(way), :created_at.desc) }

  def self.search(q)
    joins(:sites).where {
      (lower(:email) =~ lower("%#{q}%")) |
      (lower(:free_text) =~ lower("%#{q}%")) |
      (lower(sites.hostname) =~ lower("%#{q}%"))
    }
  end

  # ====================
  # = Instance Methods =
  # ====================

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

