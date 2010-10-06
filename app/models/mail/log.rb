class Mail::Log < ActiveRecord::Base
  
  set_table_name 'mail_logs'
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 10
  
  attr_accessible :template_id, :admin_id, :criteria, :user_ids
  
  serialize :criteria
  serialize :user_ids
  serialize :snapshot
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :template, :class_name => "Mail::Template"
  belongs_to :admin
  
  # ==========
  # = Scopes =
  # ==========
  # sort
  scope :by_template_title, lambda { |way| includes(:template).order("mail_templates.title #{way || 'asc'}") }
  scope :by_admin_email,    lambda { |way| includes(:admin).order("admins.email #{way || 'asc'}") }
  scope :by_date,           lambda { |way| order(:created_at.send(way || 'desc')) }
  
  # ===============
  # = Validations =
  # ===============
  validates :template_id, :presence => true
  validates :admin_id, :presence => true
  validates :criteria, :presence => true
  validates :user_ids, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  before_create :snapshotize_template
  
  # ====================
  # = Instance Methods =
  # ====================
  
protected
  
  def snapshotize_template
    self.snapshot = Mail::Template.find(template_id).snapshotize
  end
  
end