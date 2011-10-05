class MSVStats.Views.VVView extends Backbone.View
  template: JST['stats/templates/_vv_chart_legend']

  initialize: ->
    _.bindAll this, 'render', 'renderIfSelected'
    @options.period.bind 'change', this.render
    @options.statsSeconds.bind 'change', this.renderIfSelected
    @options.statsSeconds.bind 'reset', this.renderIfSelected
    @options.statsMinutes.bind 'reset', this.renderIfSelected
    @options.statsHours.bind   'reset', this.renderIfSelected
    @options.statsDays.bind    'reset', this.renderIfSelected
    this.render()

  render: ->
    if MSVStats.period.get('type')?
      $('#vv_content').show()
      $('#vv').data().spinner.stop()
      @stats = MSVStats.period.stats()
      $(@el).html(this.template(stats: @stats))
      this.renderChart()
      return this
    else
      $('#vv_content').hide()
      $('#vv').spin()
      return this

  renderIfSelected: (stats) ->
    this.render() if MSVStats.period.get('type') == stats.periodType()

  renderChart: ->
    MSVStats.vvChart = new Highcharts.Chart
      chart:
        renderTo: 'vv_chart'
        backgroundColor: null
        plotBackgroundColor: null
        animation: false
        plotShadow: false
        marginTop: 10
        marginRight: 10
        marginBottom: 50
        marginLeft: 50
        spacingTop: 5
        spacingRight: 5
        spacingBottom: 5
        spacingLeft: 5
        height: 300
        width: 848
      colors: [
        '#edc950'
        '#0046ff'
      ]
      credits:
        enabled: false
      title:
        text: null
      tooltip:
        enabled:  MSVStats.period.get('type') != 'seconds'
        # backgroundColor: null
        # snap: 50
        shared: true
        # borderColor: "#fff"
        borderWidth: 0
        borderRadius: 0
        shadow: false
        crosshairs: true
        formatter: ->
          title = ["<b>#{Highcharts.dateFormat('%e %b %Y, %H:%M:%S', @x)}</b><br/>"]
          title += _.map(@points, (point) ->
            "<b>#{point.series.name}</b><br/>#{Highcharts.numberFormat(point.y, 0)} hits"
          ).join("<br/>")
      navigator:
        enabled: false
      scrollbar:
        enabled: false
      # rangeSelector:
      #   buttons: []
      #   enabled: MSVStats.period.get('type') == 'days'
      plotOptions:
        spline:
          animation: false
          shadow: false
          borderWidth: 0
          showInLegend: false
          allowPointSelect: false
          stickyTracking: false
          lineWidth: 2
          marker:
            # enabled: false
            radius: 1
            fillColor: null
            lineColor: null
            lineWidth: 2
            states:
              hover:
                # enabled: true
                radius: 1
                fillColor: null
                lineColor: null
                lineWidth: 6
          states:
            hover:
              lineWidth: 2
          # dataGrouping:
          #   groupPixelWidth: 1
          #   smoothed: true
      series: [{
        type: 'spline'
        name: 'Page visits'
        data: @stats.customPluck('pv', MSVStats.period.get('startIndex'), MSVStats.period.get('endIndex'))
        pointInterval: MSVStats.period.pointInterval()
        pointStart: @stats.first().time()
        },{
        type: 'spline'
        name: 'Video views'
        data: @stats.customPluck('vv', MSVStats.period.get('startIndex'), MSVStats.period.get('endIndex'))
        pointInterval: MSVStats.period.pointInterval()
        pointStart: @stats.first().time()
      }]
      xAxis:
        lineWidth: 0
        tickWidth: 0
        gridLineWidth: 1
        type: 'datetime'
        # min: MSVStats.period.startTime()
        # max: MSVStats.period.endTime()
        # max: MSVStats.period.startTime() + 59 * MSVStats.period.pointInterval()
      yAxis:
        lineWidth: 0
        offset: 10
        min: 0
        allowDecimals: false
        startOnTick: false
        labels:
          align: 'right'
        title:
          text: null
