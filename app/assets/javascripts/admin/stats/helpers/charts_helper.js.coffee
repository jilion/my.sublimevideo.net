class AdminSublimeVideo.Helpers.ChartsHelper

  updateTotals: ->
    _.each AdminSublimeVideo.stats, (serie, name) =>
      if serie.length > 0 and !_.isEmpty(serie.selected)
        _.each serie.selected, (selection) =>
          startDate = AdminSublimeVideo.period.get('start')
          endDate   = AdminSublimeVideo.period.get('end')
          newStartDateAtMidnight = new Date(Date.UTC(startDate.getFullYear(), startDate.getMonth(), startDate.getDate()))
          newEndDateAtMidnight = new Date(Date.UTC(endDate.getFullYear(), endDate.getMonth(), endDate.getDate()))

          unless _.contains(['sites', 'users'], serie.id())
            allData = _.compact(serie.customPluck(selection, newStartDateAtMidnight.getTime() / 1000, newEndDateAtMidnight.getTime() / 1000))

            AdminSublimeVideo.totals[serie.title(selection)] = _.reduce(allData, ((sum, num)-> return sum + num), 0)
            AdminSublimeVideo.totals[serie.title(selection)] /= allData.length if selection[1]? and /proportion/i.test selection[1]

  listUsedYAxis: ->
    @usedYAxis = []
    _.each @collection, (serie) =>
      _.each serie.selected, (selected) =>
        if serie.length > 0 and !_.isEmpty(serie.selected) and !_.include(@usedYAxis, serie.yAxis(selected))
          @usedYAxis.push(serie.yAxis(selected))


  buildSeries: ->
    @series = []

    _.each @collection, (serie) =>
      if serie.length > 0 and !_.isEmpty(serie.selected)
        _.each serie.selected, (selected) =>
          stack = if serie.id() is 'sales' and selected[0] isnt 'total' then 1 else null

          data = serie.customPluck(selected)

          @series.push
            name: serie.title(selected)
            data: data
            type: serie.chartType(selected)
            stack: stack
            yAxis: _.indexOf(_.sortBy(@usedYAxis, (x) -> x), serie.yAxis(selected))
            pointStart: serie.startTime()
            pointInterval: 3600 * 24 * 1000

    # @series.push this.timelineSitesEvents()
    # @series.push this.timelineTweetsEvents()
    @series

  buildXAxis: ->
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
          text: "Users & sites evolution"

    if _.include(@usedYAxis, 2)
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
          text: "Tweets evolution"

    if _.include(@usedYAxis, 3)
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

    if _.include(@usedYAxis, 4)
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

    if _.include(@usedYAxis, 5)
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

    if _.include(@usedYAxis, 6)
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
          text: "Billable items evolution"

    yAxis

  chart: (collection) ->
    @collection = collection
    firstSerie = _.find(@collection, (serie) => !_.isEmpty(serie.selected))

    this.listUsedYAxis()
    this.buildSeries()

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
            AdminSublimeVideo.statsRouter.updateUrl('p', "#{newStart}-#{newEnd}")
            newStartDate = new Date(newStart)
            newEndDate   = new Date(newEnd)
            AdminSublimeVideo.period.set(start: newStartDate, end: newEndDate)
            AdminSublimeVideo.chartsHelper.updateTotals()

      navigator:
        series:
          type: firstSerie.chartType(firstSerie.selected[0]),
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

      series: @series

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
          title = ["#{Highcharts.dateFormat('%e %b %Y', @x)}<br /><br />"]
          if @point?
            title.push "<span style=\"color:#a2b1c9;font-weight:normal\">#{@point.text}</span>"
          else if @points?
            yAxis = []
            _.each @points, (point) ->
              yAxis.push(point.series.yAxis) unless _.include(yAxis, point.series.yAxis)

            _.each yAxis, (yAx) =>
              points = _.filter(@points, (point) -> point.series.yAxis is yAx)
              title.push(_.map(_.sortBy(points, (p) -> 1/p.y), (point) =>
                t = "<span style=\"color:#{point.series.color};font-weight:bold\">#{point.series.name}</span> "
                if /sales/i.test point.series.yAxis.axisTitle.textStr
                  t += "$ #{Highcharts.numberFormat(point.y, 2)}<br />$ #{Highcharts.numberFormat(AdminSublimeVideo.totals[point.series.name], 2)} (total)"
                else if /traffic/i.test point.series.yAxis.axisTitle.textStr
                  t += "#{Highcharts.numberFormat(point.y, 2)} GB<br />#{Highcharts.numberFormat(AdminSublimeVideo.totals[point.series.name], 2)} GB (total)"
                else if /percentages/i.test point.series.yAxis.axisTitle.textStr
                  t += "#{Highcharts.numberFormat(point.y, 2)} %<br />#{Highcharts.numberFormat(AdminSublimeVideo.totals[point.series.name], 2)} % (average)"
                else
                  t += "#{Highcharts.numberFormat(point.y, 0)}"
                  unless /(sites|users|billable items)/i.test point.series.yAxis.axisTitle.textStr
                    t += "<br />#{Highcharts.numberFormat(AdminSublimeVideo.totals[point.series.name], 0)} (total)"
                t
              ).join("<br />"))
              title.push("<br />")

          title.join("<br />")

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
                      top: event.point.pageY - 60
                      left: event.point.pageX
                      'z-index': '1000000'
                      width: '350px'
                      padding: '10px 20px'
                      'display': 'none'
                    popUp.html content

                    $(document).keydown (event) -> if event.which is 27 then popUp.remove() # the 'esc' key is pressed
                    popUp.click (event) -> if !event.metaKey then popUp.remove()

                    $("#content}").append popUp

                    # Move the popup left if too close to the right window's border
                    if event.point.pageX + popUp.outerWidth() + 30 > $(window).width()
                      popUp.css('left', $(window).width() - popUp.outerWidth() - 30)
                    popUp.show()

      xAxis: this.buildXAxis()

      yAxis: this.buildYAxis()


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
