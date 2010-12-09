# Simple DSL to build Highcharts graph
class Graph
  
  attr_accessor :options, :raw_options
  
  def initialize
    self.options = {}
    self.raw_options = []
    
    yield self
  end
  
  def option(hash = {})
    options.update(hash)
  end
  
  def raw_option(string = "")
    raw_options << string unless string.blank?
  end
  
  def draw(options = { :observe => "dom:loaded" })
    result = %(<script type = "text/javascript" charset="utf-8">)
    result += "document.observe('#{options[:observe]}', function() {" if options[:observe]
    result += "var chart = new Highcharts.Chart(#{draw_options});"
    result += "});" if options[:observe]
    result + "</script>"
  end
  
private
  
  def draw_options
    result = "{ "
    if options.to_json.inspect.size > 2
      result += options.to_json[1..-2]
      result += ", " if raw_options.present?
    end
    if raw_options.present?
      result << raw_options.join(", ")
    end
    result + " }"
  end
  
end