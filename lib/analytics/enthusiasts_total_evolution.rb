module Analytics
  
  class EnthusiastsTotalEvolution < Report
    include ActionView::Helpers::TranslationHelper
    AVAILABLE_COLORS = %w[#97A7BF #526D82 #f60 #5f3 #08c]
    
    def initialize(options = {})
      @start_time      = (options.key?(:start_time) ? Date.parse(options[:start_time]) : Time.zone.local(2010, 8, 1)).beginning_of_day
      @end_time        = (options.key?(:end_time) ? Date.parse(options[:end_time]) : Time.zone.now).end_of_day
      @render_engine   = options[:render_engine] || "grafico"
      @series, @labels = Analytics::SeriesBuilder::Evolution.series_and_labels({
        :total => {
          "total registered" => ::Enthusiast.scoped,
          "total confirmed" => [::Enthusiast.confirmed, :confirmed_at],
          "total confirmed & interested in beta" => [::Enthusiast.confirmed.interested_in_beta, :confirmed_at],
          "total invited" => [::Enthusiast.invited, :invited_at]
        },
        :per_day => {
          "registered" => ::Enthusiast.scoped,
          "invited" => [::Enthusiast.invited, :invited_at]
        }
      }, @start_time, @end_time)
    end
    
    def title
      "Evolution of the total of enthusiasts between #{pretty_date(@start_time)} and #{pretty_date(@end_time)}."
    end
    
    def date_can_be_changed?
      true
    end
    
    def holder_dimensions
      [1100, 800]
    end
    
    def render(options = {})
      options.reverse_merge!(:dom_id => 'charts_holder', :graph_type => 'line_graph')
      @dom_id     = options[:dom_id]
      @graph_type = options[:graph_type]
      
      html = case @render_engine
      when "grafico"
        send("#{@graph_type}_tag", @dom_id, @series, graph_options)
      end
      # sprintf("<script type='text/javascript'>document.observe('dom:loaded', function() { %s });</script>", html)
    end
    
    def graph_options
      {
        :grid                  => true,
        :start_at_zero         => true,
        :draw_hovers           => true,
        :markers               => 'value',
        :marker_size           => 0,
        :show_ticks            => false,
        :plot_padding          => 0,
        :font_size             => font_size,
        :stroke_width          => 3,
        :labels                => labels,
        :label_rotation        => -40,
        :hover_radius          => 10,
        :hide_empty_label_grid => true,
        :curve_amount          => 2,
        :datalabels            => datalabels,
        :colors                => colors#,
        # :watermark             => "/images/embed/main/cloud_icon.png"
        # :watermark_location    => "middle"
      }
    end
    
    def font_size
      11
    end
    
    def labels
      labels_count = @labels.size
      step = (labels_count.to_f / (holder_dimensions[0]/30)).ceil
      i = 0
      while i < labels_count do
        @labels[i] = '' unless i % step == 0
        i += 1
      end
      @labels
    end
    
    def datalabels
      @series.inject({}) do |memo, serie_hash|
        case @graph_type
        when 'line_graph', 'area', 'stack_graph'
          memo[serie_hash[0]] = "#{serie_hash[0].titleize}"
        end
        memo
      end
    end
    
    def colors
      i = 0
      @series.inject({}) do |memo, serie_hash|
        memo[serie_hash[0]] = AVAILABLE_COLORS[i % AVAILABLE_COLORS.size]
        i += 1
        memo
      end
    end
    
    def pretty_date(date)
      date.strftime("%b. #{date.day.ordinalize} %Y")
    end
  end
  
end