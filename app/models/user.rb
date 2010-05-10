class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :full_name, :email, :password, :password_confirmation
  
  # ================
  # = Associations =
  # ================
  
  # has_many :sites
  # has_many :videos
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates_presence_of :full_name
  
  # ====================
  # = Instance Methods =
  # ====================
  
end