# coding: utf-8
module Admin::StatsHelper

  def chart(id)
    {
      renderTo: id,
      marginTop: 100,
      backgroundColor: '#EEE'
    }
  end

  def usage_date_subtitle(start_at, end_at, options = {})
    options[:date_format] ||= :year_month_day
    {
      text: options[:text] || "#{l(start_at, format: options[:date_format].to_sym)} - #{l(end_at, format: options[:date_format].to_sym)}",
      x: -20
    }
  end

  def legend(options = {})
    {
      verticalAlign: options[:vertical_align] || :top,
      y: options[:y] || 50,
      width: options[:width] || 970,
      symbolWidth: options[:symbol_width] || 12,
      backgroundColor: options[:background_color] || '#FFFFFF',
      borderColor: options[:border_color] || '#CCC'
    }
  end

  def serie(data, title, color, options = {})
    {
      type: options[:type] || :areaspline,
      name: title,
      visible: !options[:visible].nil? ? options[:visible] : true,
      color: color,
      data: data
    }
  end

  def evolutive_average_array(array)
    zeros_days = array.select { |value| value.zero? }.size
    Array.new.tap { |arr| array.each_with_index { |item, index| arr << (item.to_f / [(index + 1 - zeros_days), 1].max).round(2) } }
  end

  def plot_options(start_at, interval = 1.day)
    {
      series: {
        pointStart: start_at.to_i * 1000,
        pointInterval: interval * 1000, # in ms
        stacking: 'normal',
        shadow: false,
        marker: {
          enabled: false,
          states: {
            hover: {
              enabled: true
            }
          }
        },
        states: {
          hover: {
            lineWidth: 2,
            marker: {
              enabled: true
            }
          }
        }
      },
      areaspline: {
        fillOpacity: 0.5
      },
      line: {
        lineWidth: 2
      }
    }
  end

  def credits
    {
      enabled: true,
      text: "Generated at: #{l(Time.now.utc, format: :seconds_timezone)} / Copyright © #{Date.today.year} - SublimeVideo®",
      href: "http://sublimevideo.net"
    }
  end

end
