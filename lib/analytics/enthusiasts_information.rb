module Analytics
  
  class EnthusiastsInformation < Report
    AVAILABLE_COLORS = %w[#97A7BF #526D82 #f60 #5f3 #08c]
    def initialize(options = {})
      @render_engine = options[:render_engine] || "grafico"
      @series, @labels, @datalabels = Analytics::SeriesBuilder::Distribution.series_and_labels([
        ["about status",
          [["confirmed & beta & invited", ::Enthusiast.confirmed.interested_in_beta.invited.size],
          ["confirmed & beta & not invited", ::Enthusiast.confirmed.interested_in_beta.not_invited.size],
          ["confirmed & not beta", ::Enthusiast.confirmed.not_interested_in_beta.size],
          ["not confirmed & beta", ::Enthusiast.not_confirmed.interested_in_beta.size],
          ["not confirmed & not beta", ::Enthusiast.not_confirmed.not_interested_in_beta.size]],
        ],
        ["about sites",
          [["having sites", ::Enthusiast.having_site(true).size],
          ["not having sites", ::Enthusiast.having_site(false).size], ['1',0], ['2',0], ['3',0]]
        ],
        ["about comments",
          [["having comment", ::Enthusiast.having_comment(true).size],
          ["not having comment", ::Enthusiast.having_comment(false).size], ['1',0], ['2',0], ['3',0]]
        ],
        ["about tags",
          [["having tags", ::Enthusiast.having_tag(true).size],
          ["not having tags", ::Enthusiast.having_tag(false).size], ['1',0], ['2',0], ['3',0]]
        ]
      ])
    end
    
    def title
      "Information on the #{::Enthusiast.all.size} registered enthusiasts."
    end
    
    def holder_dimensions
      [1100, 600]
    end
    
    def render(options = {})
      options.reverse_merge!(:dom_id => 'charts_holder', :graph_type => 'stacked_bar_graph')
      @dom_id     = options[:dom_id]
      @graph_type = options[:graph_type]
      
      html = case @render_engine
      when "grafico"
        send("#{@graph_type}_tag", @dom_id, @series, graph_options)
      # when "graphael"
      #   "var r = Raphael('#{@dom_id}');
      #   r.g.txtattr.font = \"12px 'Fontin Sans', Fontin-Sans, sans-serif\";
      #   var pie = r.g.piechart(600, 300, 150, #{js_for_series}, {
      #     legend: #{js_for_labels}, legendpos: \"north\"
      #   });
      #   pie.hover(function () {
      #     this.sector.stop();
      #     this.sector.scale(1.1, 1.1, this.cx, this.cy);
      #     if (this.label) {
      #       this.label[0].stop();
      #       this.label[0].scale(1.5);
      #       this.label[1].attr({ 'font-weight': 800 });
      #     }
      #   }, function () {
      #       this.sector.animate({ scale: [1, 1, this.cx, this.cy] }, 500, 'bounce');
      #       if (this.label) {
      #         this.label[0].animate({ scale: 1 }, 500, 'bounce');
      #         this.label[1].attr({ 'font-weight': 400 });
      #       }
      #   });"
      end
      # sprintf("<script type='text/javascript'>document.observe('dom:loaded', function() { %s });</script>", html)
    end
    
    def graph_options
      {
        :grid                  => true,
        :show_ticks            => false,
        :font_size             => 12,
        :labels                => labels,
        :datalabels            => datalabels,
        # :label_rotation        => -20,
        :colors                => colors,
        :hover_color           => "#CCAA00"
      }
    end
    
    def colors
      i = 0
      @series.inject({}) do |memo, serie_hash|
        memo[serie_hash[0]] = AVAILABLE_COLORS[i % AVAILABLE_COLORS.size]
        i += 1
        memo
      end
    end
    
    def labels
      @labels
    end
    
    def datalabels
      @datalabels
    end
    
  #   def js_for_series
  #     @series.values.inspect
  #   end
  #   
  #   def js_for_labels
  #     @labels.inspect
  #   end
  #   
  #   def js_for_colors
  #     available_colors = %w[#97A7BF #526D82 #f60 #5f3 #08c]
  #     i = 0
  #     colors = @series.inject([]) do |memo, serie_hash|
  #       memo << "#{serie_hash[0]}: '#{available_colors[i % available_colors.size]}'"
  #       i += 1
  #       memo
  #     end.join(", ")
  #     "{ #{colors} }"
  #   end
  
  end
  
end