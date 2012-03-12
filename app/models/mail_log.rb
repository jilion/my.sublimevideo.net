class MailLog < ActiveRecord::Base

  attr_accessible :template_id, :admin_id, :criteria, :user_ids

  serialize :criteria
  serialize :user_ids
  serialize :snapshot

  # ================
  # = Associations =
  # ================

  belongs_to :template, :class_name => "MailTemplate", :foreign_key => "template_id"
  belongs_to :admin

  # ===============
  # = Validations =
  # ===============
  
  validates :template_id, :presence => true
  validates :admin_id,    :presence => true
  validates :criteria,    :presence => true
  validates :user_ids,    :presence => true

  # =============
  # = Callbacks =
  # =============
  
  before_create :snapshotize_template

  # ==========
  # = Scopes =
  # ==========
  
  # sort
  scope :by_template_title, lambda { |way = 'asc'| includes(:template).order(:template => :title.send(way)) }
  scope :by_admin_email,    lambda { |way = 'asc'| includes(:admin).order(:admin => :email.send(way)) }
  scope :by_date,           lambda { |way = 'desc'| order(:created_at.send(way)) }

  # ====================
  # = Instance Methods =
  # ====================

private

  def snapshotize_template
    self.snapshot = MailTemplate.find(template_id).snapshotize
  end

end
# == Schema Information
#
# Table name: mail_logs
#
#  id          :integer         not null, primary key
#  template_id :integer
#  admin_id    :integer
#  criteria    :text
#  user_ids    :text
#  snapshot    :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_mail_logs_on_template_id  (template_id)
#

