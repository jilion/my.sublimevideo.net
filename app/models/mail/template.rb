class Mail::Template < ActiveRecord::Base
  
  set_table_name 'mail_templates'
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 10
  
  # ===============
  # = Validations =
  # ===============
  validates :title, :presence => true, :uniqueness => true
  validates :subject, :presence => true
  validates :body, :presence => true
  
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

