class Mail::Template < ActiveRecord::Base
  
  set_table_name 'mail_templates'
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 10
  
  attr_accessible :title, :subject, :body
  
  # ================
  # = Associations =
  # ================
  
  has_many :logs, :class_name => "Mail::Log"
  
  # ==========
  # = Scopes =
  # ==========
  # sort
  scope :by_title, lambda { |way| order(:title.send(way || 'asc')) }
  scope :by_date,  lambda { |way| order(:created_at.send(way || 'desc')) }
  
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

