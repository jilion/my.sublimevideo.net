class MSVStats.Helpers.ChartsHelper

  sparkline: (el, serie, options = {}) ->
    el.sparkline serie,
      width: options.width
      height: options.height
      lineColor: options.lineColor ? (if options.selected then '#1ce937' else '#59c775')
      fillColor: options.fillColor ? (if options.selected then '#71bb93' else '#4c7b75')

    # new Highcharts.Chart
    #   chart:
    #     animation: false
    #     renderTo: el[0]
    #     margin: [0,0,0,0]
    #     borderWidth: 0
    #     borderRadius: 0
    #     backgroundColor: 'transparent'
    #     # height: options.height
    #     # width:  options.width
    #     events:
    #       click: options.click
    #   series: [
    #     type: 'areaspline'
    #     data: serie
    #     color: if options.selected then '#0046ff' else '#00b1ff'
    #   ]
    #   credits:
    #     enabled: false
    #   title:
    #     text: null
    #   legend:
    #     enabled: false
    #   tooltip:
    #     enabled: false
    #   xAxis:
    #     title: ""
    #     labels:
    #       enabled: false
    #   yAxis:
    #     title: ""
    #     endOnTick: false
    #     labels:
    #       enabled: false
    #   plotOptions:
    #     areaspline:
    #       animation: false
    #       stickyTracking: false
    #       enableMouseTracking: false
    #       borderWidth: 0
    #       pointPadding: 0
    #       pointWidth: 4
    #       shadow: true
    #       marker:
    #         enabled: false


  vvChart: (stats) ->
    MSVStats.vvChart = new Highcharts.Chart
      chart:
        renderTo: 'vv_chart'
        backgroundColor: 'transparent'
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
      #   enabled: MSVStats.period.isDays()
      plotOptions:
        areaspline:
          showInLegend: false
          animation: false
          states:
            hover:
              lineWidth: 2
        column:
          showInLegend: false
          animation: false
        series:[{
          shadow: false
          borderWidth: 0
          allowPointSelect: false
          stickyTracking: false
          lineWidth: 2
          marker:
            enabled: true
            radius: 1
            lineWidth: 2
            states:
              hover:
                enabled: false
                # radius: 1
                # fillColor: null
                # lineColor: null
                # lineWidth: 6
          states:
            hover:
              lineWidth: 2
        }]
      series: [{
        type: stats.chartType()
        name: 'Page visits'
        data: stats.customPluck('pv', MSVStats.period.get('startIndex'), MSVStats.period.get('endIndex'))
        pointInterval: MSVStats.period.pointInterval()
        pointStart: MSVStats.period.startTime()
        shadow: false
        color: '#627c9f'
        lineColor: '#596e8c'
        # point:
        #   color: '#000000'
        marker:
          enabled: false
          # fillColor: '#596e8c'
          # lineColor: '#596e8c'
        },{
        type: stats.chartType()
        name: 'Video views'
        data: stats.customPluck('vv', MSVStats.period.get('startIndex'), MSVStats.period.get('endIndex'))
        pointInterval: MSVStats.period.pointInterval()
        pointStart: MSVStats.period.startTime()
        shadow: true
        color: '#578b8d'
        lineColor: '#74ff83'
        # point:
        #   color: '#74ff83'
        marker:
          symbol: 'circle'
          fillColor: '#74ff83'
          lineColor: '#74ff83'
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
