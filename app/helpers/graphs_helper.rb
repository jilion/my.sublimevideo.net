# coding: utf-8
module GraphsHelper

  def chart(id, options = {})
    options.reverse_merge!(margin_top: 110, margin_bottom: 50, margin_left: 90, background_color: '#EEEEEE')

    {
      renderTo: id,
      marginTop: options[:margin_top],
      marginBottom: options[:margin_bottom],
      marginLeft: options[:margin_left],
      marginRight: options[:margin_right],
      backgroundColor: options[:background_color],
      animation: false
    }
  end

  def stats_date_subtitle(options = {})
    options.reverse_merge!(start_at: nil, end_at: nil, text: nil, date_format: 'year_month_day')

    {
      text: options[:text] || "#{l(options[:start_at], format: options[:date_format].to_sym)} - #{l(options[:end_at], format: options[:date_format].to_sym)}",
      x: -20
    }
  end

  def legend(options = {})
    options.reverse_merge!(enabled: true, vertical_align: 'top', y: 40, width: 970, symbol_width: 12, background_color: '#FFF', border_color: '#CCC')

    {
      enabled: options[:enabled],
      verticalAlign: options[:vertical_align],
      y: options[:y],
      width: options[:width],
      symbolWidth: options[:symbol_width],
      backgroundColor: options[:background_color],
      borderColor: options[:border_color]
    }
  end

  def x_axis(options = {})
    options.reverse_merge!(show_first_label: true, start_at: nil, end_at: nil, steps: 12, min: 0, plot_bands: [], plot_lines: [])

    tick_interval = ((options[:end_at] - options[:start_at]) / options[:steps].days).floor
    {
      type: 'datetime',
      showFirstLabel: options[:show_first_label],
      max: options[:end_at].to_i * 1000,
      tickInterval: tick_interval.days * 1000,
      labels: {
        y: 15
      },
      dateTimeLabelFormats: {
        day: '%e %b',
        week: '%e %b'
      },
      plotBands: options[:plot_bands].each_with_object([]) { |plot_band_options, array| array << plot_band(plot_band_options) },
      plotLines: options[:plot_lines].each_with_object([]) { |plot_line_options, array| array << plot_line(plot_line_options) }
    }
  end

  def plot_band(options = {})
    options.reverse_merge!(color: '#FFFFD9', from: 30.days.ago.midnight, to: Time.now.utc)

    {
      color: options[:color],
      from: options[:from].to_i * 1000,
      to: options[:to].to_i * 1000
    }
  end

  def plot_line(options = {})
    options.reverse_merge!(width: 2, color: '#FFFFD9', value: 30.days.ago.midnight)

    {
      width: options[:width],
      color: options[:color],
      value: options[:value].to_i * 1000
    }
  end

  def y_axis(title, options = {})
    options.reverse_merge!(show_first_label: true, margin: 70, min: 0, tick_interval: 'null')

    %(yAxis: {
      showFirstLabel: #{options[:show_first_label]},
      title: {
        text: '#{title}',
        margin: #{options[:margin]}
      },
      min: #{options[:min]},
      tickInterval: #{options[:tick_interval]},
      labels: {
        formatter: function() { return Highcharts.numberFormat(this.value, 0); }
      }
    })
  end

  def tooltip(options = {})
    options.reverse_merge!(formatter: %(function() {
      var date  = "<strong>" + Highcharts.dateFormat("%B %e,  %Y", this.x) + "</strong><br/><br/>";
      var label = "<strong>" + Highcharts.numberFormat(this.y, 0) + "</strong>";

      if (["Invalid", "Dev", "Extra", "Main"].indexOf(this.series.name) != -1) {
        label += " of " + Highcharts.numberFormat(this.total, 0) + " (" + Highcharts.numberFormat(this.percentage, 1) + "%)";
      }
      else if (this.series.name == "Loader") {
        label += "<br/>Loader / Player: " + Highcharts.numberFormat((this.y / (this.total - this.y)), 1);
      }

      return date + this.series.name + " hits:<br/>" + label;
    }))

    %(tooltip: {
      borderWidth: 0,
      backgroundColor: "rgba(0, 0, 0, .70)",
      style: {
        color: '#FFFFFF',
        padding: '5px'
      },
      formatter: function() { #{options[:formatter]} }
    })
  end

  def serie(data, title, options = {})
    options.reverse_merge!(type: 'area', visible: true, stack: nil)

    {
      type: options[:type],
      stack: options[:stack],
      name: title,
      visible: options[:visible],
      color: options[:color],
      fillColor: options[:fill_color],
      data: data
    }
  end

  def plot_options(start_at, interval = 1.day, options = {})
    options.reverse_merge!(marker: false, marker_hover: true, visible: true, stacking: 'normal')
    points = options[:linear] ? {} : { pointStart: start_at.to_i * 1000, pointInterval: interval * 1000 }

    {
      series: points.merge({
        stacking: options[:stacking], shadow: false, fillOpacity: 0.4,
        marker: {
          enabled: options[:marker],
          radius: 3,
          states: { hover: { enabled: options[:marker_hover] } }
        },
        states: {
          hover: {
            lineWidth: 1
          }
        }
      }),
      line: { lineWidth: 1 },
      area: { lineWidth: 1 },
      areaspline: { lineWidth: 1 },
      column: { borderWidth: 0, pointPadding: 0, pointWidth: 6 }
    }
  end

  def credits(options = {})
    options.reverse_merge!(enabled: true, visible: true)

    {
      enabled: options[:enabled],
      text: "Generated at: #{l(Time.now.utc, format: :seconds_timezone)} / Copyright © #{Date.today.year} - SublimeVideo®",
      href: 'http://sublimevideo.net'
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

end
