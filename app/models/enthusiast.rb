# == Schema Information
#
# Table name: enthusiasts
#
#  id         :integer         not null, primary key
#  email      :string(255)
#  free_text  :text
#  created_at :datetime
#  updated_at :datetime
#

class Enthusiast < ActiveRecord::Base
  
  attr_accessible :email, :free_text, :sites_attributes
  
  # ================
  # = Associations =
  # ================
  
  has_many :sites, :class_name => "EnthusiastSite", :dependent => :destroy
  accepts_nested_attributes_for :sites, :reject_if => lambda { |a| a[:hostname].blank? }, :allow_destroy => true
  
  # ===============
  # = Validations =
  # ===============
  
  validates :email, :presence => true, :uniqueness => true
  
end