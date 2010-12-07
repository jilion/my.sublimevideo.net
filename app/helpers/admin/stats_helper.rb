# coding: utf-8
module Admin::StatsHelper
  
  def plot_options(start_at, interval = 1.day)
     {
      :column => {
        :pointInterval => interval * 1000, # in ms
        :pointStart => start_at.to_i * 1000,
        :stacking => 'normal',
        :shadow => false
      },
      :line => {
        :pointInterval => interval * 1000,
        :pointStart => start_at.to_i * 1000,
        :lineWidth => 2,
        :marker => {
          :enabled => false
        },
        :shadow => false,
        :states => {
          :hover => {
            :lineWidth => 2,
            :marker => {
              :enabled => true
            }
          }
        }
      }
    }
  end
  
  def credits
    {
      :enabled => true,
      :text => "Generation time: #{l(Time.now.in_time_zone('Bern'), :format => :seconds_timezone)} / Copyright © #{Date.today.year} - SublimeVideo®",
      :href => "http://sublimevideo.net"
    }
  end
  
end