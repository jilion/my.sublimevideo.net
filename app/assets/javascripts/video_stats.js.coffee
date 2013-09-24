MySublimeVideo.videoStats ||= {}

MySublimeVideo.videoStatsReady = ->
  MySublimeVideo.videoStats.prepareAutoSubmitForHoursSelect()
  MySublimeVideo.videoStats.prepareCSVExportButton()

MySublimeVideo.videoStats.initSparklines = ->
  $.fn.sparkline.defaults.line.disableHighlight = true
  $.fn.sparkline.defaults.line.disableTooltips  = true
  $.fn.sparkline.defaults.line.spotRadius       = 0
  $.fn.sparkline.defaults.line.lineWidth        = 0
  $.fn.sparkline.defaults.line.spotColor        = false
  $.fn.sparkline.defaults.line.minSpotColor     = false
  $.fn.sparkline.defaults.line.maxSpotColor     = false
  $.fn.sparkline.defaults.line.drawNormalOnTop  = true
  $.fn.sparkline.defaults.line.chartRangeClip   = true
  $.fn.sparkline.defaults.line.chartRangeMin    = 0

MySublimeVideo.videoStats.refreshTopStats = ->
  since = $('#last_plays li').first().data('time')
  $.ajax
    url: MySublimeVideo.Helpers.HistoryHelper.currentUrlWithNewQuery('since', since)
    dataType: 'script'

MySublimeVideo.videoStats.refreshBottomStats = ->
  $('#video_stats_dates_range_and_source_selector').submit()
  $('#video_stats_hours_select, #video_stats_source_select').prop('disabled', true)
  $('#vv, #bp .content_wrap, #co .content_wrap').spin()

MySublimeVideo.videoStats.prepareAutoSubmitForHoursSelect = ->
  $('#video_stats_hours_select, #video_stats_source_select').on 'change', (event) ->
    $select = $(event.target)
    MySublimeVideo.videoStats.refreshBottomStats()
    MySublimeVideo.Helpers.HistoryHelper.updateQueryInUrl($select.prop('name'), $select.val())

MySublimeVideo.videoStats.prepareCSVExportButton = ->
  $('#csv_export').on 'click', (event) ->
    event.preventDefault()
    currentLocation = document.location
    csvLocation = "#{currentLocation.protocol}//#{currentLocation.hostname}#{currentLocation.pathname}.csv#{currentLocation.search}"
    window.open(csvLocation)

    false

class MySublimeVideo.Helpers.VideoStatsChartsHelper

  @sparkline: (el, serie, options = {}) ->
    el.sparkline serie,
      width: options.width
      height: options.height
      lineColor: options.lineColor ? 'rgba(97,255,114,0.7)'
      fillColor: options.fillColor ? 'rgba(116,255,131,0.24)'

  @loadsAndStartsChart: (loads, starts, hours) ->
    new Highcharts.StockChart
      chart:
        renderTo: 'video_loads_and_starts_chart'
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
      rangeSelector:
        enabled: false
      credits:
        enabled: false
      title:
        text: null
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
          format = if hours > 24 then '%e %b %Y' else '%e %b %Y, %H:%M'
          title = ["#{Highcharts.dateFormat(format, @x)}<br/>"]

          title += _.map(@points, (point) ->
            "<span style=\"color:#a2b1c9;font-weight:normal\">#{point.series.name}</span> #{Highcharts.numberFormat(point.y, 0)} hits"
          ).join("<br/>")
      navigator:
        enabled: false
      scrollbar:
        enabled: false
      plotOptions:
        series:
          showInLegend: false
          animation: false
          shadow: false
          borderWidth: 0
          allowPointSelect: false
          stickyTracking: false
          lineWidth: 2
          marker:
            states:
              hover:
                enabled: false
          states:
            hover:
              lineWidth: 2
      series: [{
        type: 'areaspline'
        name: 'Loads'
        data: loads
        shadow: false
        fillColor: 'rgba(74,100,142,0.3)'
        color: '#596e8c'
        marker:
          enabled: false
        },{
        type: 'areaspline'
        name: 'Plays'
        data: starts
        shadow:
          color: 'rgb(116, 255, 131)'
          offsetX: 1e-100
          offsetY: 1e-100
          opacity: 0.22
          width: 6
        fillColor: 'rgba(9,250,33,0.15)'
        color: '#00ff18'
        marker:
          enabled: false
      }]
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
      yAxis:
        lineWidth: 0
        offset: 0
        min: 0
        gridLineColor: '#5d7493'
        allowDecimals: false
        startOnTick: false
        showFirstLabel: false
        labels:
          x: -30
          y: 5
          style:
            fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
            fontSize: "14px"
            color: '#1e3966'
        title:
          text: null

  @mobilesAndDesktopsChart: (data) ->
    new Highcharts.Chart
      chart:
        renderTo: 'mobiles_and_desktops_chart'
        backgroundColor: 'transparent'
        plotBackgroundColor: null
        animation: false
        plotShadow: false
        height: 260
        width: 260
      credits:
        enabled: false
      title:
        text: null
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
        shadow: true
        style:
          padding: "10"
          fontFamily: "proxima-nova-1, proxima-nova-2, Helvetica, Arial, sans-serif"
          fontSize: "15px"
          fontWeight: "bold"
          textAlign: "right"
          color: '#fff'
          textShadow: 'rgba(0,0,0,0.8) 0 -1px 0'
          WebkitFontSmoothing: "antialiased"
        formatter: ->
          "<span style=\"color:#a2b1c9;font-weight:normal\">#{@point.name}</span> #{Highcharts.numberFormat(@point.y, 0)} plays"
      scrollbar:
        enabled: false
      plotOptions:
        pie:
          dataLabels:
            enabled: false
          states:
            hover:
              enabled: false
      series: [{
        type: 'pie'
        name: 'Mobile / Desktop'
        data: data
        shadow: false
      }]
