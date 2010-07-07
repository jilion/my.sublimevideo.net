# == Schema Information
#
# Table name: enthusiast_sites
#
#  id            :integer         not null, primary key
#  enthusiast_id :integer
#  hostname      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class EnthusiastSite < ActiveRecord::Base
  
  attr_accessible :hostname
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :enthusiast
  
  # ===============
  # = Validations =
  # ===============
  
  validates :hostname, :presence => true, :production_hostname => true
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # add scheme & parse
  def hostname=(attribute)
    if attribute.present?
      attribute.downcase!
      attribute = "http://#{attribute}" unless attribute =~ %r(^\w+://.*$)
      attribute.gsub! %r(://www\.), '://'
      begin
        write_attribute :hostname, URI.parse(attribute).host
      rescue
        write_attribute :hostname, attribute.gsub(%r(.+://(www\.)?), '')
      end
    end
  end
  
end