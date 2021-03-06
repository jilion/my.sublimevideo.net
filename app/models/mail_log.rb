class MailLog < ActiveRecord::Base
  serialize :criteria
  serialize :user_ids
  serialize :snapshot

  belongs_to :template, class_name: 'MailTemplate', foreign_key: 'template_id'
  belongs_to :admin

  validates :template_id, :admin_id, :criteria, :user_ids, presence: true

  before_create :snapshotize_template

  # sort
  scope :by_template_title, ->(way = 'asc') { includes(:template).order("templates.title #{way}") }
  scope :by_admin_email,    ->(way = 'asc') { includes(:admin).order("admins.email #{way}") }
  scope :by_date,           ->(way = 'desc') { order(created_at: way.to_sym) }

  private

  def snapshotize_template
    self.snapshot = MailTemplate.find(template_id).snapshotize
  end

end

# == Schema Information
#
# Table name: mail_logs
#
#  admin_id    :integer
#  created_at  :datetime
#  criteria    :text
#  id          :integer          not null, primary key
#  snapshot    :text
#  template_id :integer
#  updated_at  :datetime
#  user_ids    :text
#
# Indexes
#
#  index_mail_logs_on_template_id  (template_id)
#

