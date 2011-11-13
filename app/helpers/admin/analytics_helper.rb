module Admin::AnalyticsHelper

  def include_appropriate_js(js_engine = "grafico")
    js_files = case js_engine
    when "grafico"
      ["raphael-min.js", "grafico.min.js"]
    when "graphael"
      ["raphael-min.js", "graphael/g.raphael-min.js", "graphael/g.pie-min.js"]
    when "flotr"
      ["flotr/flotr-0.2.0-alpha.js", "flotr/lib/base64.js", "flotr/lib/canvas2image.js", "flotr/lib/canvastext.js"]
    end
    content_for :js do
      javascript_include_tag(*js_files) if js_files
    end
  end

  def start_time_select_options(selected_date = 1.month.ago.beginning_of_day)
    options = (1..6).inject([]) do |memo, month_i|
      memo << [month_i, month_i.month.ago.beginning_of_day]
    end
    [options, { :selected => params[:opts] && params[:opts][:start_time] ? params[:opts][:start_time] : selected_date }]
  end

end
