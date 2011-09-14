#= require jquery.textfill/jquery.textfill

class MSVStats.Views.VVView extends Backbone.View
  template: JST['stats/templates/_vv_chart']

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);
    this.options.period.bind('change', this.render);

    $('#vv_chart').bind 'mouseleave', ->
      MSVStats.vvChartLegend.clearIndex()

  render: ->
    @vvData = this.collection.vvData()
    $(this.el).html(this.template(vvData: @vvData))

    $('#vv_content').show()
    $('#vv').data().spinner.stop()

    $('#pv_number').textfill(maxFontPixels: 70 )
    $('#vv_number').textfill(maxFontPixels: 70 )
    this.renderChart()
    return this

  periodicRender: ->
    # call each minute (0 seconds)
    if MSVStats.Models.Period.today().date.getTime() == MSVStats.Models.Period.today({s: 0}).date.getTime()
      MSVStats.stats.clearCache()
      MSVStats.vvView.render()
      window.setTimeout(( -> MSVStats.vvView.periodicRender()), 57000)
    else
      window.setTimeout(( -> MSVStats.vvView.periodicRender()), 1000)

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
        spacingTop: 0
        spacingRight: 0
        spacingBottom: 0
        spacingLeft: 0
        height: 300
        width: 700
      colors: [
        '#edc950'
        '#65384a'
      ]
      credits:
        enabled: false
      title:
        text: null
      tooltip:
        backgroundColor: null
        snap: 300
        shared: true
        borderWidth: 0
        borderRadius: 0
        shadow: false
        # crosshairs: true
        formatter: () ->

        # shared: true
        # enabled: false
        # crosshairs: true
        # borderWidth: 0
        # shadow: false
        # shared: true
        # formatter: ->
        #   MSVStats.period.periodChartTitle(@x)
        #   title = [""] #["<b>#{MSVStats.period.periodChartTitle(@x)}</b><br/><br/>"]
        #   title += _.map(@points, (point) ->
        #     "<b>#{point.series.name}</b><br/>#{Highcharts.numberFormat(point.y, 0)} hits"
        #   ).join("<br/>")
      plotOptions:
        spline:
          animation: false
          shadow: false
          borderWidth: 0
          showInLegend: false
          # allowPointSelect: false
          stickyTracking: false
          lineWidth: 2
          point:
            events:
              mouseOver: ->
                # clear selected points
                console.log 'mouseOver'
                MSVStats.vvChart.series[0].data[0].select(false, false)
                index = _.indexOf(xChartValues, this.x)
                MSVStats.vvChartLegend.setIndex(index)
                console.log MSVStats.vvChartLegend.get('index')
          marker:
            radius: 2
            fillColor: null
            lineColor: null
            lineWidth: 2
            states:
              hover:
                radius: 4
                fillColor: null
                lineColor: "#FFFFFF"
                lineWidth: 2
              select:
                radius: 4
                fillColor: null
                lineColor: "#FFFFFF"
                lineWidth: 2
          states:
            hover:
              lineWidth: 2
      series: [{
        type: MSVStats.period.periodChartType()
        name: 'Page visits'
        data: @vvData.pv
        pointInterval: MSVStats.period.periodInterval()
        pointStart: MSVStats.stats.currentPeriodStartDate()
        },{
        type: MSVStats.period.periodChartType()
        name: 'Video views'
        data: @vvData.vv
        pointInterval: MSVStats.period.periodInterval()
        pointStart: MSVStats.stats.currentPeriodStartDate()
      }]
      xAxis:
        lineWidth: 0
        tickInterval: null # MSVStats.period.periodTickInterval()
        tickWidth: 0
        gridLineWidth: 1
        type: 'datetime'
        plotBands: [
          color: '#1fedff'
          from: MSVStats.stats.currentPeriodStartDate() + (@vvData.pv.length - 2) * MSVStats.period.periodInterval()
          to: MSVStats.stats.currentPeriodStartDate() + (@vvData.pv.length - 0.5) * MSVStats.period.periodInterval()
          zIndex: 2
          label:
            text: 'Curremt'
            rotation: 90
            textAlign: 'left'
            x: -5
            y: 5
        ]
      yAxis:
        min: 0
        allowDecimals: false
        startOnTick: false
        title:
          text: null

    xChartValues = _.map(MSVStats.vvChart.series[0].data, ((o) -> o.x))
    if selectedIndex = MSVStats.vvChartLegend.get('index')
      MSVStats.vvChart.series[0].data[selectedIndex].select(true, false)
      MSVStats.vvChart.series[1].data[selectedIndex].select(true, true)
