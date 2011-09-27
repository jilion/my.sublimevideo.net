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
    $('#vv_chart_legend').html(this.render().el)

  render: ->    
    if MSVStats.period.get('type')?
      $('#vv_content').show()
      $('#vv').data().spinner.stop()
      @stats = MSVStats.period.stats()
      $(this.el).html(this.template(stats: @stats))
      this.renderChart()
      return this
    else
      $('#vv_content').hide()
      $('#vv').spin()
      return this
      
  renderIfSelected: (stats) ->
    this.render() if MSVStats.period.get('type') == stats.periodType()

  renderChart: ->
    console.log MSVStats.statsSeconds.length
    console.log MSVStats.period.startTime()
    console.log MSVStats.period.endTime()
    console.log MSVStats.period.endTime() - MSVStats.period.startTime()
    MSVStats.vvChart = new Highcharts.StockChart
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
      rangeSelector:
        buttons: []
        enabled: MSVStats.period.get('type') == 'days'
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
            radius: 2
            fillColor: null
            lineColor: null
            lineWidth: 2
            states:
              hover:
                radius: 4
                fillColor: null
                lineColor: null
                lineWidth: 0
          states:
            hover:
              lineWidth: 2
          dataGrouping:
            groupPixelWidth: 1
            smoothed: true
      series: [{
        type: 'spline'
        name: 'Page visits'
        data: @stats.pluck('pv')
        pointInterval: MSVStats.period.typeInterval()
        pointStart: @stats.first().time()
        },{
        type: 'spline'
        name: 'Video views'
        data: @stats.pluck('vv')
        pointInterval: MSVStats.period.typeInterval()
        pointStart: @stats.first().time()
      }]
      xAxis:
        lineWidth: 0
        tickWidth: 0
        gridLineWidth: 1
        type: 'datetime'
        min: MSVStats.period.startTime()
        # max: MSVStats.period.endTime()
        max: MSVStats.period.startTime() + 59 * MSVStats.period.typeInterval()
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

    # MSVStats.vvChart.xAxis[0].setExtremes(1235001600000, 1317425472000)
    # xChartValues = _.map(MSVStats.vvChart.series[0].data, ((o) -> o.x))
    # if selectedIndex = MSVStats.vvChartLegend.get('index')
    #   MSVStats.vvChart.series[0].data[selectedIndex].select(true, false)
    #   MSVStats.vvChart.series[1].data[selectedIndex].select(true, true)
