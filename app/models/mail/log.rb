class Mail::Log < ActiveRecord::Base
  
  set_table_name 'mail_logs'
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 10
  
  attr_accessible :template_id, :admin_id, :criteria, :user_ids, :snapshot
  
  serialize :criteria
  serialize :user_ids
  serialize :snapshot
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :template, :class_name => "Mail::Template"
  belongs_to :admin
  
  # ===============
  # = Validations =
  # ===============
  validates :template_id, :presence => true
  validates :admin_id, :presence => true
  validates :criteria, :presence => true
  validates :user_ids, :presence => true
  validates :snapshot, :presence => true
  
  # =================
  # = Class Methods =
  # =================
  
  def self.deliver_and_save_log(params)
    users = User
    users = if params[:criteria].is_a?(Array)
      params[:criteria].each { |c| users = users.send(c) }
      users
    else
      users.send(params[:criteria])
    end.all
    
    template = Mail::Template.find(params[:template_id])
    
    users.each { |u| self.delay.deliver(u, template) }
    
    self.create(params.merge(:user_ids => users.map(&:id), :snapshot => template.snapshotize))
  end
  
private
  
  def self.deliver(user, template)
    MailMailer.send_mail_with_template(user, template).deliver
  end
  
end