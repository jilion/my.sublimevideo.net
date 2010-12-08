# coding: utf-8
module Admin::StatsHelper
  
  def chart(id)
    {
      renderTo: id,
      marginTop: 100,
      backgroundColor: '#EEE'
    }
  end
  
  def usage_date_subtitle(start_at)
    {
      text: "#{l(start_at, :format => :seconds_timezone)} - #{l(Time.now, :format => :seconds_timezone)}",
      x: -20
    }
  end
  
  def usage_legend
    {
      verticalAlign: 'top',
      y: 50,
      width: 970,
      symbolWidth: 12,
      backgroundColor: '#FFFFFF',
      borderColor: '#CCC'
    }
  end
  
  def serie(data, title, color, options = {})
    {
      type: options[:type] || 'column',
      name: title,
      visible: !options[:visible].nil? ? options[:visible] : true,
      color: color,
      data: data
    }
  end
  
  def average_array(array)
    Array.new.tap { |arr| array.each_with_index { |item, index| arr << (item / (index + 1)).to_i } }
  end
  
  def usage_plot_options(start_at, interval = 1.day)
     {
      column: {
        pointInterval: interval * 1000, # in ms
        pointStart: start_at.to_i * 1000,
        stacking: 'normal',
        shadow: false
      },
      line: {
        pointInterval: interval * 1000,
        pointStart: start_at.to_i * 1000,
        lineWidth: 2,
        marker: {
          enabled: false
        },
        shadow: false,
        states: {
          hover: {
            lineWidth: 2,
            marker: {
              enabled: true
            }
          }
        }
      }
    }
  end
  
  def credits
    {
      :enabled => true,
      :text => "Generated at: #{l(Time.now.in_time_zone('Bern'), :format => :seconds_timezone)} / Copyright © #{Date.today.year} - SublimeVideo®",
      :href => "http://sublimevideo.net"
    }
  end
  
end