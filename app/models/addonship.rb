class Addonship < ActiveRecord::Base
  
  belongs_to :plan
  belongs_to :addon
  
end



# == Schema Information
#
# Table name: addonships
#
#  id         :integer         not null, primary key
#  plan_id    :integer
#  addon_id   :integer
#  price      :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_addonships_on_addon_id              (addon_id)
#  index_addonships_on_plan_id               (plan_id)
#  index_addonships_on_plan_id_and_addon_id  (plan_id,addon_id)
#

