class SVStats.Helpers.ChartsHelper

  sparkline: (el, serie, options = {}) ->
    el.sparkline serie,
      width: options.width
      height: options.height
      lineColor: options.lineColor ? (if options.selected then '#00ff18' else 'rgba(97,255,114,0.7)')
      fillColor: options.fillColor ? (if options.selected then 'rgba(116,255,131,0.46)' else 'rgba(116,255,131,0.24)')

  chart: (collections) ->
    series = this.buildSeries(collections)
    SVStats.chart = new Highcharts.StockChart
      chart:
        renderTo: 'chart'
      credits:
        enabled: false
      title:
        text: null
      rangeSelector:
        buttonTheme:
          fill: 'none'
          # stroke: 'none'
          style:
            color: '#039'
            fontWeight: 'bold'
          states:
            hover:
              fill: 'white'
            select:
              style:
                color: 'white'
        inputStyle:
          color: '#039'
          fontWeight: 'bold'
        labelStyle:
          color: 'silver'
          fontWeight: 'bold'
        buttons: [{
          type: 'all'
          text: 'All'
        }, {
          type: 'year'
          count: 1
          text: '1 y'
        }, {
          type: 'month'
          count: 6
          text: '6 m'
        }, {
          type: 'month'
          count: 3
          text: '3 m'
        }, {
          type: 'month'
          count: 1
          text: '30 d'
        }, {
          type: 'week'
          count: 1
          text: '7 d'
        }]
        selected: 4
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
      series: series
      xAxis:
        lineWidth: 0
        tickWidth: 0
        gridLineWidth: 0
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
          text: "Users & Sites evolution"

  buildSeries: (collections) ->
    series = []
    _.each collections, (collection) ->
      if collection.length > 0
        series.push
          id: collection.id()
          name: collection.title()
          data: collection.customPluck()
          type: collection.chartType()
          color: collection.color()
          pointStart: collection.startTime()
          pointInterval: 24 * 60 * 60 * 1000

    series.push this.timelineSitesEvents()
    series.push this.timelineTweetsEvents()
    series

  timelineSitesEvents: ->
    type: 'flags'
    data: [{
      x: Date.UTC(2011, 2, 29)
      title: 'V1'
      text: 'SublimeVideo commercial launch!'
    }, {
      x: Date.UTC(2011, 10, 29)
      title: 'V2'
      text: 'SublimeVideo unleashed!'
    }]
    onSeries: 'sites'
    shape: 'circlepin'
    width: 16

  timelineTweetsEvents: ->
    type: 'flags'
    data: [{
      x: Date.UTC(2011, 5, 10)
      title: 'CS1'
      text: 'Customer Showcase: WordPress 101'
    }, {
      x: Date.UTC(2011, 8, 20)
      title: 'WP'
      text: "Introducing the Official SublimeVideo WordPress Plugin"
    }, {
      x: Date.UTC(2011, 6, 27)
      title: 'FS'
      text: "World's First True HTML5 Fullscreen Video"
    }]
    onSeries: 'tweets'
    shape: 'circlepin'
    width: 16
