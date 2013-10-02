class Plan < ActiveRecord::Base
  # Used in _grandfather_plan_text.html.haml
  def title(options = {})
    "#{name.gsub(/\d/, '').titleize.strip} Plan" + (cycle == 'year' ? ' (yearly)' : '')
  end
end

# == Schema Information
#
# Table name: plans
#
#  created_at           :datetime
#  cycle                :string(255)
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  price                :integer
#  stats_retention_days :integer
#  support_level        :integer          default(0)
#  token                :string(255)
#  updated_at           :datetime
#  video_views          :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

