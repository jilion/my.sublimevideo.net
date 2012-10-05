# class Addons::Addonship < ActiveRecord::Base

# end
# # == Schema Information
# #
# # Table name: addonships
# #
# #  addon_id         :integer          not null
# #  created_at       :datetime         not null
# #  id               :integer          not null, primary key
# #  site_id          :integer          not null
# #  state            :string(255)      not null
# #  trial_started_on :datetime
# #  updated_at       :datetime         not null
# #
# # Indexes
# #
# #  index_addonships_on_addon_id              (addon_id)
# #  index_addonships_on_site_id_and_addon_id  (site_id,addon_id) UNIQUE
# #  index_addonships_on_state                 (state)
# #  index_addonships_on_trial_started_on      (trial_started_on)
# #

# # == Schema Information
# #
# # Table name: addonships
# #
# #  addon_id         :integer          not null
# #  created_at       :datetime         not null
# #  id               :integer          not null, primary key
# #  site_id          :integer          not null
# #  state            :string(255)      not null
# #  trial_started_on :datetime
# #  updated_at       :datetime         not null
# #
# # Indexes
# #
# #  index_addonships_on_addon_id              (addon_id)
# #  index_addonships_on_site_id_and_addon_id  (site_id,addon_id) UNIQUE
# #  index_addonships_on_state                 (state)
# #  index_addonships_on_trial_started_on      (trial_started_on)
# #

