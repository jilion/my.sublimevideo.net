class SVStats.Helpers.ChartsHelper

  chart: (collections) ->
    SVStats.chart = new Highcharts.StockChart
      chart:
        renderTo: 'chart'

      series: this.buildSeries(collections)

      credits:
        enabled: false

      title:
        text: null

      rangeSelector:
        buttonTheme:
          fill: 'none'
          style:
            color: '#039'
            fontWeight: 'bold'
          states:
            select:
              style:
                color: 'black'
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

      tooltip:
        enabled: true
        backgroundColor:
          linearGradient: [0, 0, 0, 60]
          stops: [
              [0, 'rgba(22,37,63,0.8)']
              [1, 'rgba(0,0,0,0.7)']
          ]
        # snap: 50
        shared: true
        borderColor: "#000"
        borderWidth: 1
        borderRadius: 5
        shadow: true,
        style:
          padding: "10"
          fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
          fontSize: "15px"
          fontWeight: "bold"
          textAlign: "right"
          color: '#fff'
          textShadow: 'rgba(0,0,0,0.8) 0 -1px 0'
          WebkitFontSmoothing: "antialiased"
        crosshairs:[{
          width: 1
          color: '#5d7493'
        }]
        formatter: ->
          title = ["#{Highcharts.dateFormat('%e %b %Y, %H:%M:%S', @x)}<br/>"]
          if @point?
            title += ["<span style=\"color:#a2b1c9;font-weight:normal\">#{@point.text}</span>"]
          else if @points?
            title += _.map(_.sortBy(@points, (p) -> 1/p.y), (point) ->
              "<span style=\"color:#a2b1c9;font-weight:normal\">#{point.series.name}</span>#{Highcharts.numberFormat(point.y, 0)}"
            ).join("<br/>")
          title

      plotOptions:
        flags:
          shape: 'circlepin'

      xAxis:
        type: 'datetime'
        # lineWidth: 0
        # tickWidth: 0
        # gridLineWidth: 0
        gridLineColor: '#5d7493'
        labels:
          y: 21
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'

      yAxis:
        lineWidth: 1
        # offset: 10
        # min: 0
        gridLineColor: '#5d7493'
        allowDecimals: false
        startOnTick: false
        showFirstLabel: false
        labels:
          align: 'right'
          x: -4
          y: 4
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
        title:
          text: "Users, sites & tweets evolution"

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
          pointInterval: 3600 * 24 * 1000

    # series.push this.timelineSitesEvents()
    # series.push this.timelineTweetsEvents()
    series

  timelineSitesEvents: ->
    type: 'flags'
    data: [{
      x: Date.UTC(2011, 2, 29)
      title: 'V1'
      text: 'SublimeVideo commercial launch!'
    }, {
      x: Date.UTC(2011, 10, 29, 22)
      title: 'V2'
      text: 'SublimeVideo unleashed!'
    }]
    # onSeries: 'sites'
    width: 16

  timelineTweetsEvents: ->
    type: 'flags'
    data: [{
      x: Date.UTC(2011, 5, 10)
      title: 'BP1'
      text: 'Customer Showcase: WordPress 101'
    }, {
      x: Date.UTC(2011, 8, 20)
      title: 'BP2'
      text: "Introducing the Official SublimeVideo WordPress Plugin"
    }, {
      x: Date.UTC(2011, 6, 27)
      title: 'BP3'
      text: "World's First True HTML5 Fullscreen Video"
    }]
    # onSeries: 'tweets'
    width: 16
