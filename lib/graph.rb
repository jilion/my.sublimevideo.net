# Simple DSL to build Highcharts graph
class Graph

  def initialize
    @options     = {}
    @raw_options = []

    yield self
  end

  def option(hash={})
    @options.update(hash)
  end

  def raw_option(string)
    @raw_options << string
  end

  def draw(options={ :observe => "dom:loaded" })
    result = "var chart = new Highcharts.Chart(#{draw_options});"
    result = "document.observe('#{options[:observe]}', function() {" + result + "});" if options[:observe]

    '<script type="text/javascript" charset="utf-8">' + result + "</script>"
  end

private

  def draw_options
    result = "{ "
    if @options.to_json.inspect.size > 2
      result += @options.to_json[1..-2]
      result += ", " if @raw_options.present?
    end
    result << @raw_options.join(", ") if @raw_options.present?
    result + " }"
  end

end
