class MailTemplate < ActiveRecord::Base

  attr_accessible :title, :subject, :body, :archived_at

  has_many :logs, class_name: 'MailLog', foreign_key: 'template_id'

  validates :title,   presence: true, uniqueness: true
  validates :subject, :body, presence: true

  scope :archived,     -> { where.not(archived_at: nil) }
  scope :not_archived, -> { where(archived_at: nil) }
  scope :by_title,     ->(way = 'asc') { order(title: way.to_sym) }
  scope :by_date,      ->(way = 'desc') { order(created_at: way.to_sym) }

  def snapshotize
    { title: title, subject: subject, body: body }
  end

end

# == Schema Information
#
# Table name: mail_templates
#
#  archived_at :datetime
#  body        :text
#  created_at  :datetime         not null
#  id          :integer          not null, primary key
#  subject     :string(255)
#  title       :string(255)
#  updated_at  :datetime         not null
#

