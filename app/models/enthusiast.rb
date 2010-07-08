# == Schema Information
#
# Table name: enthusiasts
#
#  id                   :integer         not null, primary key
#  user_id              :integer
#  email                :string(255)
#  free_text            :text
#  confirmation_token   :string(255)
#  confirmed_at         :datetime
#  confirmation_sent_at :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

class Enthusiast < ActiveRecord::Base
  
  devise :validatable, :confirmable
  
  attr_accessible :email, :free_text, :sites_attributes
  
  cattr_accessor :per_page
  self.per_page = 25
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many :sites, :class_name => "EnthusiastSite", :dependent => :destroy
  accepts_nested_attributes_for :sites, :reject_if => lambda { |a| a[:hostname].blank? }, :allow_destroy => true
  
  # ===============
  # = Validations =
  # ===============
  
  validates :email, :presence => true, :uniqueness => true
  
protected
  
  def password_required?
    false
  end
  
end
