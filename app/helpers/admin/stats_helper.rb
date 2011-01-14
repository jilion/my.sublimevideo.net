# coding: utf-8
module Admin::StatsHelper

  def chart(id, options={})
    {
      renderTo: id,
      marginTop: options[:margin_top] || 100,
      marginLeft: options[:margin_left] || 90,
      backgroundColor: '#FEFEFE',
      borderWidth: 1,
      marginBottom: 50
    }
  end

  def usage_date_subtitle(start_at, end_at, options={})
    options[:date_format] ||= :year_month_day
    {
      text: options[:text] || "#{l(start_at, format: options[:date_format].to_sym)} - #{l(end_at, format: options[:date_format].to_sym)}",
      x: -20
    }
  end

  def legend(options={})
    {
      enabled: options[:enabled].nil? ? true : options[:enabled],
      verticalAlign: options[:vertical_align] || :top,
      y: options[:y] || 50,
      width: options[:width] || 970,
      symbolWidth: options[:symbol_width] || 12,
      backgroundColor: options[:background_color] || '#FFFFFF',
      borderColor: options[:border_color] || '#CCC'
    }
  end

  def serie(data, title, color, options={})
    {
      type: options[:type] || :areaspline,
      name: title,
      visible: options[:visible].nil? ? true : options[:visible],
      # color: color,
      data: data
    }
  end

  def evolutive_average_array(array)
    zeros_days = array.select { |value| value.zero? }.size
    Array.new.tap { |arr| array.each_with_index { |item, index| arr << (item.to_f / [(index + 1 - zeros_days), 1].max).round(2) } }
  end

  def plot_options(start_at, interval=1.day, options={})
    points = options[:linear] ? {} : { pointStart: start_at.to_i * 1000, pointInterval: interval * 1000 }
    {
      series: points.merge({
        stacking: 'normal', shadow: false, fillOpacity: 0.4,
        marker: {
          enabled: options[:marker] || false,
          states: { hover: { enabled: true } }
        },
        states: {
          hover: {
            lineWidth: 2,
            marker: { enabled: true }
          }
        }
      }),
      line: { lineWidth: 2 }
    }
  end

  def credits(options={})
    {
      enabled: options[:enabled].nil? ? true : options[:enabled],
      text: "Generated at: #{l(Time.now.utc, format: :seconds_timezone)} / Copyright © #{Date.today.year} - SublimeVideo®",
      href: "http://sublimevideo.net"
    }
  end

end
