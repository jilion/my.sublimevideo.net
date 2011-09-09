#= require jquery.textfill/jquery.textfill

class MSVStats.Views.VVView extends Backbone.View
  template: JST['stats/templates/_vv_chart']

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);
    this.options.period.bind('change', this.render);

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
      MSVStats.stats.clearcurrentPeriodStatsCache()
      MSVStats.vvView.render()
      window.setTimeout(( -> MSVStats.vvView.periodicRender()), 57000)
    else
      window.setTimeout(( -> MSVStats.vvView.periodicRender()), 1000)

  renderChart: ->
    new Highcharts.Chart
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
        crosshairs: true
        borderWidth: 0
        shadow: false
        shared: true
        formatter: ->
          title = ["<b>#{MSVStats.period.periodChartTitle(@x)}</b><br/><br/>"]
          title += _.map(@points, (point) ->
            "<b>#{point.series.name}</b><br/>#{Highcharts.numberFormat(point.y, 0)} hits"
          ).join("<br/>")
      plotOptions:
        column:
          animation: false
          shadow: false
          borderWidth: 0
          showInLegend: false
          allowPointSelect: false
          stickyTracking: false
          lineWidth: 3
          dataLabels:
            enabled: false
          states:
            hover:
              enabled: false
              lineWidth: 3
              marker:
                enabled: false
        spline:
          animation: false
          shadow: false
          borderWidth: 0
          showInLegend: false
          allowPointSelect: false
          stickyTracking: false
          lineWidth: 3
          marker:
            enabled: false
          dataLabels:
            enabled: false
          states:
            hover:
              enabled: false
              lineWidth: 3
              marker:
                enabled: false
      series: [{
        type: MSVStats.period.periodChartType()
        name: 'Page visits'
        data: @vvData.pv
        },{
        type: MSVStats.period.periodChartType()
        name: 'Video views'
        data: @vvData.vv
      }]
      xAxis:
        lineWidth: 0
        tickInterval: MSVStats.period.periodTickInterval()
        tickWidth: 0
        gridLineWidth: 1
        type: 'datetime'
      yAxis:
        min: 0
        allowDecimals: false
        startOnTick: false
        title:
          text: null

