# coding: utf-8
module Admin::StatsHelper

  def chart(id, options={})
    {
      renderTo: id,
      marginTop: options[:margin_top] || 110,
      marginBottom: options[:margin_bottom] || 50,
      marginLeft: options[:margin_left] || 90,
      backgroundColor: '#EEEEEE',
      animation: false
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
      y: options[:y] || 40,
      width: options[:width] || 970,
      symbolWidth: options[:symbol_width] || 12,
      backgroundColor: options[:background_color] || '#FFFFFF',
      borderColor: options[:border_color] || '#CCC'
    }
  end
  
  def x_axis(start_at, end_at, interval=1.day, options={})
    {
      type: 'datetime',
      max: end_at.to_i * 1000,
      tickInterval: interval * 1000,
      labels: {
        step: ((end_at - start_at) / 12.day).floor,
        y: 15
      },
      dateTimeLabelFormats: {
      	day: '%e %b',
      	week: '%e %b'
      },
      plotBands: [{
        color: '#FFFFD9',
        from: (Time.now.utc.beginning_of_day - 30.days).to_i * 1000,
        to: Time.now.utc.beginning_of_day.to_i * 1000
      }]
    }
  end

  def y_axis(title, options={})
    %(yAxis: {
      title: {
        text: '#{title}',
        margin: #{options[:margin] || 70}
      },
      min: #{options[:min] || 0},
      labels: {
        formatter: function() { return Highcharts.numberFormat(this.value, 0); }
      }
    })
  end
  
  def tooltip(options={})
    default_formatter = %(function() {
      var date  = "<strong>" + Highcharts.dateFormat("%B %e,  %Y", this.x) + "</strong><br/><br/>";
      var label = "<strong>" + Highcharts.numberFormat(this.y, 0) + "</strong>";

      if (["Invalid", "Dev", "Extra", "Main"].indexOf(this.series.name) != -1) {
        label += " of " + Highcharts.numberFormat(this.total, 0) + " (" + Highcharts.numberFormat(this.percentage, 1) + "%)";
      }
      else if (this.series.name == "Loader") {
        label += "<br/>Loader / Player: " + Highcharts.numberFormat((this.y / (this.total - this.y)), 1);
      }

      return date + this.series.name + " hits:<br/>" + label;
    })
    
    %(tooltip: {
      borderWidth: 0,
      backgroundColor: "rgba(0, 0, 0, .70)",
      style: {
      	color: '#FFFFFF',
      	padding: '5px'
      },
      formatter: function() { #{options[:formatter] || default_formatter} }
    })
  end

  def serie(data, title, color, options={})
    {
      type: options[:type] || :areaspline,
      name: title,
      visible: options[:visible].nil? ? true : options[:visible],
      # color: color, # automatic colors
      data: data
    }
  end

  def evolutive_average_array(array)
    zeros_days = array.select { |value| value.zero? }.size
    Array.new.tap { |arr| array.each_with_index { |item, index| arr << (item.to_f / [(index + 1 - zeros_days), 1].max).round(2) } }
  end
  
  def moving_average(array, range)
    Array.new.tap do |arr|
      (0..(array.size - range)).each do |index|
        arr << array[index, range].mean
      end
    end
  end

  def plot_options(start_at, interval=1.day, options={})
    points = options[:linear] ? {} : { pointStart: start_at.to_i * 1000, pointInterval: interval * 1000 }
    {
      series: points.merge({
        stacking: 'normal', shadow: false, fillOpacity: 0.4,
        marker: {
          enabled: options[:marker] || false,
          radius: 3,
          states: { hover: { enabled: true } }
        },
        states: {
          hover: {
            lineWidth: 1
          }
        }
      }),
      line: { lineWidth: 1 },
      areaspline: { lineWidth: 1 }
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
