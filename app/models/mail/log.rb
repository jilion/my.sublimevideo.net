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
  scope :by_template_title, lambda { |way = 'asc'| includes(:template).order("#{Mail::Template.quoted_table_name}.title #{way}") }
  scope :by_admin_email,    lambda { |way = 'asc'| includes(:admin).order("#{Admin.quoted_table_name}.email #{way}") }
  scope :by_date,           lambda { |way = 'desc'| order("#{Mail::Log.quoted_table_name}.created_at #{way}") }
  
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