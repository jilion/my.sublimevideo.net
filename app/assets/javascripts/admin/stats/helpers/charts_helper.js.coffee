class SVStats.Helpers.ChartsHelper

  sparkline: (el, serie, options = {}) ->
    el.sparkline serie,
      width: options.width
      height: options.height
      lineColor: options.lineColor ? (if options.selected then '#00ff18' else 'rgba(97,255,114,0.7)')
      fillColor: options.fillColor ? (if options.selected then 'rgba(116,255,131,0.46)' else 'rgba(116,255,131,0.24)')

  chart: (collections) ->
    SVStats.chart = new Highcharts.StockChart
      chart:
        renderTo: 'chart'
        # backgroundColor: 'transparent'
        # plotBackgroundColor: null
        # animation: false
        # plotShadow: false
        # marginTop: 10
        # marginRight: 10
        # marginBottom: 50
        # marginLeft: 50
        # spacingTop: 5
        # spacingRight: 5
        # spacingBottom: 5
        # spacingLeft: 5
        # height: 300
        # width: 848
      credits:
        enabled: false
      title:
        text: null
      # tooltip:
      #   enabled: MSVStats.period.get('type') != 'seconds'
      #   backgroundColor:
      #     linearGradient: [0, 0, 0, 60]
      #     stops: [
      #         [0, 'rgba(22,37,63,0.8)']
      #         [1, 'rgba(0,0,0,0.7)']
      #     ]
      #   # snap: 50
      #   shared: true
      #   borderColor: "#000"
      #   borderWidth: 1
      #   borderRadius: 5
      #   shadow: true,
      #   style:
      #     padding: "10"
      #     fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
      #     fontSize: "15px"
      #     fontWeight: "bold"
      #     textAlign: "right"
      #     color: '#fff'
      #     textShadow: 'rgba(0,0,0,0.8) 0 -1px 0'
      #     WebkitFontSmoothing: "antialiased"
      #   crosshairs:[{
      #     width: 1
      #     color: '#5d7493'
      #   }]
      #   formatter: ->
      #     title = ["#{Highcharts.dateFormat('%e %b %Y, %H:%M:%S', @x)}<br/>"]
      #     title += _.map(@points, (point) ->
      #       "<span style=\"color:#a2b1c9;font-weight:normal\">#{point.series.name}</span>#{Highcharts.numberFormat(point.y, 0)} hits"
      #     ).join("<br/>")
      # navigator:
      #   enabled: false
      # scrollbar:
      #   enabled: false
      # rangeSelector:
      #   buttons: []
      #   enabled: MSVStats.period.isDays()
      # plotOptions:
      #   areaspline:
      #     showInLegend: false
      #     animation: false
      #     states:
      #       hover:
      #         lineWidth: 2
      #   column:
      #     borderWidth: 0
      #     pointPadding: 0
      #     # pointWidth: stats.pointWidth(788)
      #     showInLegend: false
      #     animation: false
      #   series:[{
      #     shadow: false
      #     borderWidth: 0
      #     allowPointSelect: false
      #     stickyTracking: false
      #     lineWidth: 2
      #     marker:
      #       enabled: true
      #       radius: 1
      #       lineWidth: 2
      #       states:
      #         hover:
      #           enabled: false
      #     states:
      #       hover:
      #         lineWidth: 2
      #   }]
      series: [
        #_.each collections, (collection) ->
        data: collections[0].customPluck('fr')
        type: collections[0].chartType()
        pointStart: collections[0].startTime()
        pointInterval: 24 * 60 * 60 * 1000
      ]
      #   type: stats.chartType()
      #   name: 'Page visits'
      #   data: stats.customPluck('pv', MSVStats.period.get('startIndex'), MSVStats.period.get('endIndex'))
      #   pointInterval: MSVStats.period.pointInterval()
      #   pointStart: MSVStats.period.startTime()
      #   shadow: false
      #   fillColor: 'rgba(74,100,142,0.3)'
      #   color: '#596e8c'
      #   lineColor: '#596e8c'
      #   marker:
      #     enabled: false
      #   },{
      #   type: stats.chartType()
      #   name: 'Video views'
      #   data: stats.customPluck('vv', MSVStats.period.get('startIndex'), MSVStats.period.get('endIndex'))
      #   pointInterval: MSVStats.period.pointInterval()
      #   pointStart: MSVStats.period.startTime()
      #   shadow: true
      #   fillColor: 'rgba(9,250,33,0.15)'
      #   color: '#00ff18'
      #   lineColor: '#00ff18'
      #   marker:
      #     symbol: "url(<%= asset_path 'my/stats/graph_dot.png' %>)"
      # }]
      xAxis:
        lineWidth: 0
        tickWidth: 0
        gridLineWidth: 1
        type: 'datetime'
        gridLineColor: '#5d7493'
        labels:
          y: 21
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
            # fontWeight: 'bold'
        # min: MSVStats.period.startTime()
        # max: MSVStats.period.endTime()
        # max: MSVStats.period.startTime() + 59 * MSVStats.period.pointInterval()
      yAxis:
        lineWidth: 0
        offset: 0
        min: 0
        gridLineColor: '#5d7493'
        allowDecimals: false
        startOnTick: false
        showFirstLabel: false
        labels:
          align: 'right'
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
        title:
          text: null
