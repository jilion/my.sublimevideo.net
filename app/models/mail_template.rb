class MailTemplate < ActiveRecord::Base

  attr_accessible :title, :subject, :body, :archived_at

  # ================
  # = Associations =
  # ================

  has_many :logs, class_name: "MailLog", foreign_key: "template_id"

  # ===============
  # = Validations =
  # ===============

  validates :title,   presence: true, uniqueness: true
  validates :subject, :body, presence: true

  # ==========
  # = Scopes =
  # ==========

  scope :archived,     -> { where{ archived_at != nil } }
  scope :not_archived, -> { where(archived_at: nil) }
  scope :by_title,     ->(way = 'asc') { order{ title.send(way) } }
  scope :by_date,      ->(way='desc') { order{ created_at.send(way) } }

  # ====================
  # = Instance Methods =
  # ====================

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

