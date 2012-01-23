class SVStats.Helpers.ChartsHelper

  chart: (collections) ->
    SVStats.chart = new Highcharts.StockChart
      chart:
        renderTo: 'chart'
        spacingBottom: 45

      series: this.buildSeries(collections)

      credits:
        enabled: false

      title:
        text: null

      rangeSelector:
        buttonSpacing: 3
        buttonTheme:
          fill: 'none'
          style:
            color: '#039'
            fontWeight: 'bold'
          states:
            select:
              fill: 'none'
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

      legend:
        enabled: true
        floating: true
        align: 'left'
        margin: 50
        y: 35
        borderWidth: 0

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
          title = ["#{Highcharts.dateFormat('%e %b %Y', @x)}<br/>"]
          if @point?
            title += ["<span style=\"color:#a2b1c9;font-weight:normal\">#{@point.text}</span>"]
          else if @points?
            yAxis = []
            _.each @points, (point) ->
              yAxis.push(point.series.yAxis) unless _.include(yAxis, point.series.yAxis)

            _.each yAxis, (yAx) =>
              points = _.filter(@points, (point) -> point.series.yAxis is yAx)
              title += _.map(_.sortBy(points, (p) -> 1/p.y), (point) ->
                switch point.series.yAxis.axisTitle.textStr
                  when 'Percentages'
                    "<span style=\"color:#a2b1c9;font-weight:normal\">#{point.series.name}</span>#{Highcharts.numberFormat(point.y, 1)} %"
                  when 'Traffic (GB)'
                    "<span style=\"color:#a2b1c9;font-weight:normal\">#{point.series.name}</span>#{Highcharts.numberFormat(point.y, 2)}"
                  else
                    "<span style=\"color:#a2b1c9;font-weight:normal\">#{point.series.name}</span>#{Highcharts.numberFormat(point.y, 0)}"
              ).join("<br/>")
              title += "<br/><br/>" unless _.indexOf(yAxis, yAx) is yAxis.length - 1

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

      yAxis: this.buildYAxis()

    if SVStats.statsRouter.xAxisMin? and SVStats.statsRouter.xAxisMax?
      SVStats.chart.xAxis[0].setExtremes(SVStats.statsRouter.xAxisMin, SVStats.statsRouter.xAxisMax)

  buildSeries: (collections) ->
    series = []
    @usedYAxis = []
    _.each collections, (collection) =>
      _.each collection.selected, (selected) =>
        if collection.length > 0 and !_.isEmpty(collection.selected) and !_.include(@usedYAxis, collection.yAxis(selected))
          @usedYAxis.push(collection.yAxis(selected))

    _.each collections, (collection) =>
      if collection.length > 0 and !_.isEmpty(collection.selected)
        _.each collection.selected, (selected) =>
          series.push
            name: collection.title(selected)
            data: collection.customPluck(selected)
            type: collection.chartType(selected)
            yAxis: _.indexOf(_.sortBy(@usedYAxis, (x) -> x), collection.yAxis(selected))
            # fillColor: collection.fillColor(selected)
            # color: collection.color(selected)
            # lineColor: collection.lineColor(selected)
            shadow: collection.lineColor(selected)
            pointStart: collection.startTime()
            pointInterval: 3600 * 24 * 1000

    # series.push this.timelineSitesEvents()
    # series.push this.timelineTweetsEvents()
    series

  buildYAxis: ->
    yAxis = []
    if _.include(@usedYAxis, 0)
      yAxis.push
        lineWidth: 1
        min: 0
        gridLineColor: '#5d7493'
        allowDecimals: false
        startOnTick: true
        showFirstLabel: true
        showLastLabel: true
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

    if _.include(@usedYAxis, 1)
      yAxis.push
        lineWidth: 1
        min: 0
        gridLineColor: '#5d7493'
        allowDecimals: false
        startOnTick: true
        showFirstLabel: true
        showLastLabel: true
        labels:
          align: 'right'
          x: -4
          y: 4
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
        title:
          text: "Site Stats/Usages"

    if _.include(@usedYAxis, 2)
      yAxis.push
        lineWidth: 1
        opposite: true
        min: 0
        max: 100
        alignTicks: false
        gridLineColor: '#5d7493'
        allowDecimals: true
        startOnTick: true
        showFirstLabel: true
        showLastLabel: true
        labels:
          align: 'left'
          x: 4
          y: 4
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
        title:
          text: "Percentages"

    if _.include(@usedYAxis, 3)
      yAxis.push
        lineWidth: 1
        opposite: true
        min: 0
        alignTicks: false
        gridLineColor: '#5d7493'
        allowDecimals: true
        startOnTick: true
        showFirstLabel: true
        showLastLabel: true
        labels:
          align: 'left'
          x: 4
          y: 4
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
        title:
          text: "Traffic (GB)"

    yAxis

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
