class MailTemplate < ActiveRecord::Base
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 10
  
  attr_accessible :title, :subject, :body
  
  # ================
  # = Associations =
  # ================
  
  has_many :logs, :class_name => "MailLog", :foreign_key => "template_id"
  
  # ==========
  # = Scopes =
  # ==========
  # sort
  scope :by_title, lambda { |way = 'asc'| order("#{MailTemplate.quoted_table_name}.title #{way}") }
  scope :by_date,  lambda { |way = 'desc'| order("#{MailTemplate.quoted_table_name}.created_at #{way}") }
  
  # ===============
  # = Validations =
  # ===============
  validates :title, :presence => true, :uniqueness => true
  validates :subject, :presence => true
  validates :body, :presence => true
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def snapshotize
    { :title => title, :subject => subject, :body => body }
  end
  
end

# == Schema Information
#
# Table name: mail_templates
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  subject    :string(255)
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#
