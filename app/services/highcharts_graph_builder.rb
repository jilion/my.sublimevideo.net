# Simple DSL to build Highcharts graph
class HighchartsGraphBuilder

  def initialize
    @options     = {}
    @raw_options = []

    yield self
  end

  def option(hash = {})
    @options.update(hash)
  end

  def raw_option(string)
    @raw_options << string
  end

  def draw(options = { on_dom_ready: true })
    result = "new Highcharts.Chart(#{draw_options});"
    result = '$(document).ready(function() {' + result + '});' if options[:on_dom_ready]

    '<script type="text/javascript">' + result + '</script>'
  end

private

  def draw_options
    result = '{ '
    if @options.to_json.inspect.size > 2
      result << @options.to_json[1..-2]
      result << ', ' if @raw_options.present?
    end
    result << @raw_options.join(', ') if @raw_options.present?

    "#{result} }"
  end

end
