class AdminSublimeVideo.Helpers.ChartsHelper

  chart: (collections) ->
    firstCollection = _.find(collections, (collection) => !_.isEmpty(collection.selected))

    AdminSublimeVideo.statsChart = new Highcharts.StockChart
      chart:
        renderTo: 'chart'
        spacingBottom: 45
        reflow: true
        animation: false
        plotShadow: false
        events:
          redraw: (event) ->
            newStart = parseInt @xAxis[0].getExtremes()['min']
            newEnd   = parseInt @xAxis[0].getExtremes()['max']
            AdminSublimeVideo.period.start = new Date newStart
            AdminSublimeVideo.period.end   = new Date newEnd
            AdminSublimeVideo.statsRouter.updateUrl('p', "#{newStart}-#{newEnd}")
            AdminSublimeVideo.timeRangeTitleView.render()

      navigator:
        series:
          type: firstCollection.chartType(firstCollection.selected[0]),
          color: '#4572A7',
          fillOpacity: 0.4,
          dataGrouping:
            smoothed: true
          lineWidth: 1
          marker:
            enabled: false
          shadow: false
        xAxis:
          labels:
            y: -15

      series: this.buildSeries(collections)

      credits:
        enabled: false

      title:
        text: null

      rangeSelector:
        enabled: false

      legend:
        enabled: true
        floating: true
        align: 'left'
        margin: 50
        y: 25
        borderWidth: 0
        itemHoverStyle:
          cursor: 'default'
          color: '#3E576F'

      tooltip:
        enabled: true
        backgroundColor:
          linearGradient: [0, 0, 0, 60]
          stops: [
              [0, 'rgba(22,37,63,0.8)']
              [1, 'rgba(0,0,0,0.7)']
          ]
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
          title = ["#{Highcharts.dateFormat('%e %b %Y', @x)}<br />"]
          if @point?
            title += ["<span style=\"color:#a2b1c9;font-weight:normal\">#{@point.text}</span>"]
          else if @points?
            yAxis = []
            _.each @points, (point) ->
              yAxis.push(point.series.yAxis) unless _.include(yAxis, point.series.yAxis)

            _.each yAxis, (yAx) =>
              points = _.filter(@points, (point) -> point.series.yAxis is yAx)
              title += _.map(_.sortBy(points, (p) -> 1/p.y), (point) ->
                t = "<span style=\"color:#{point.series.color};font-weight:bold\">#{point.series.name}</span>"
                t += if point.series.yAxis.axisTitle.textStr.match /sales/i
                  "$ #{Highcharts.numberFormat(point.y, 2)}"
                else if point.series.yAxis.axisTitle.textStr.match /traffic/i
                  "#{Highcharts.numberFormat(point.y, 2)} GB"
                else if point.series.yAxis.axisTitle.textStr.match /percentages/i
                  "#{Highcharts.numberFormat(point.y, 2)} %"
                else
                  "#{Highcharts.numberFormat(point.y, 0)}"
                t
              ).join("<br/>")
              title += "<br/><br/>" unless _.indexOf(yAxis, yAx) is yAxis.length - 1

          title

      plotOptions:
        flags:
          shape: 'flag'
        areaspline:
          fillOpacity: 0.25
        column:
          stacking: 'normal'
        series:
          events:
            legendItemClick: ->
              false

            click: (event) ->
              if /sales/i.test(event.point.series.name)
                $('#invoice_popup').remove()
                position = "#{event.pageX}, #{event.pageY}"
                startedAt = new Date event.point.x
                year  = startedAt.getFullYear()
                month = startedAt.getMonth()
                day   = startedAt.getDate()
                renewParam = if /total/i.test(event.point.series.name)
                  ''
                else if /renew/i.test(event.point.series.name)
                  'renew=true&'
                else if /subscription/i.test(event.point.series.name)
                  'renew=false&'
                startedAt = encodeURIComponent "#{year}-#{month+1}-#{day} 00:00:00"
                endedAt   = encodeURIComponent "#{year}-#{month+1}-#{day} 23:59:59"

                $.ajax
                  url: "/invoices.json?#{renewParam}paid_between[started_at]=#{startedAt}&paid_between[ended_at]=#{endedAt}&by_amount=desc",
                  context: document.body,
                  success: (data, textStatus, jqXHR) ->
                    content = "<strong>#{Highcharts.dateFormat('%e %b %Y', event.point.x)}</strong><br />"
                    content += "<ul>"
                    _.each data, (invoice) ->
                      content += "<li><p>"
                      content += if invoice.renew then "Renew" else "<strong>New</strong>"
                      content += " / <a href='/sites/#{invoice.site.token}/edit'>#{invoice.site_hostname}</a> / <a href='/invoices/#{invoice.reference}'>$#{Highcharts.numberFormat(invoice.amount/100, 2)}</a></p>"
                      content += "<p>by <a href='/users/#{invoice.site.user_id}'>#{invoice.user.name or invoice.user.email}</a></p>"
                      content += "</li>"
                    content += "</ul>"

                    popUp = $('<div>').attr('id', 'invoice_popup').css
                      position: 'absolute'
                      top: event.pageY - 60
                      left: event.pageX
                      'z-index': '1000000'
                      width: '350px'
                      padding: '10px 20px'
                      'display': 'none'
                    popUp.html content

                    $(document).keydown (event) -> if event.which is 27 then popUp.remove() # the 'esc' key is pressed
                    popUp.click (event) -> if !event.metaKey then popUp.remove()

                    $("#content}").append popUp

                    # Move the popup left if too close to the right window's border
                    if event.pageX + popUp.outerWidth() + 30 > $(window).width()
                      popUp.css('left', $(window).width() - popUp.outerWidth() - 30)
                    popUp.show()

      xAxis:
        type: 'datetime'
        min: AdminSublimeVideo.period.startTime()
        max: AdminSublimeVideo.period.endTime()
        gridLineColor: '#5d7493'
        lineWidth: 2
        lineColor: '#000'
        labels:
          y: 21
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'

      yAxis: this.buildYAxis()

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
          stack = if collection.id() is 'sales' and selected[0] isnt 'total' then 1 else null

          series.push
            name: collection.title(selected)
            data: collection.customPluck(selected)
            type: collection.chartType(selected)
            stack: stack
            yAxis: _.indexOf(_.sortBy(@usedYAxis, (x) -> x), collection.yAxis(selected))
            pointStart: collection.startTime()
            pointInterval: 3600 * 24 * 1000

    # series.push this.timelineSitesEvents()
    # series.push this.timelineTweetsEvents()
    series

  buildYAxis: ->
    yAxis = []

    if _.include(@usedYAxis, 0)
      yAxis.push
        lineWidth: 2
        lineColor: '#000'
        min: 0
        allowDecimals: true
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
        title:
          text: "Sales ($)"

    if _.include(@usedYAxis, 1)
      yAxis.push
        lineWidth: 2
        lineColor: '#000'
        min: 0
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
        title:
          text: "Users, sites & tweets evolution"

    if _.include(@usedYAxis, 2)
      yAxis.push
        lineWidth: 2
        lineColor: '#000'
        opposite: true
        min: 0
        allowDecimals: false
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
        title:
          text: "Site Stats/Usages"

    if _.include(@usedYAxis, 3)
      yAxis.push
        lineWidth: 2
        lineColor: '#000'
        opposite: true
        min: 0
        max: 100
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
        title:
          text: "Percentages"

    if _.include(@usedYAxis, 4)
      yAxis.push
        lineWidth: 2
        lineColor: '#000'
        opposite: true
        min: 0
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
        title:
          text: "Traffic (GB)"

    yAxis

  timelineSitesEvents: ->
    type: 'flags'
    data: [{
      x: Date.UTC(2011, 2, 30)
      title: 'V1'
      text: 'SublimeVideo commercial launch!'
    }, {
      x: Date.UTC(2011, 10, 29)
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
