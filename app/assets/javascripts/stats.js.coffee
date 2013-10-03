MySublimeVideo.stats ||= {}

MySublimeVideo.statsReady = ->
  MySublimeVideo.stats.prepareAutoSubmitForHoursSelect()
  MySublimeVideo.stats.prepareCSVExportButton()
  MySublimeVideo.stats.prepareTimeAgo()
  MySublimeVideo.stats.drawLast60MinutesPlaysAndLoadsSparklines()
  MySublimeVideo.stats.drawPlaysAndLoadsGraph()

MySublimeVideo.stats.prepareTimeAgo = ->
  $.timeago.settings.refreshMillis = 1000
  $('abbr.timeago').timeago()

MySublimeVideo.stats.initSparklines = ->
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

MySublimeVideo.stats.drawLast60MinutesPlaysAndLoadsSparklines = ->
  MySublimeVideo.stats.initSparklines()
  if ($last_60_minutes_plays = $('#last_60_minutes_plays')).exists()
    MySublimeVideo.Helpers.VideoStatsChartsHelper.sparkline($last_60_minutes_plays)

  if ($last_60_minutes_loads = $('#last_60_minutes_loads')).exists()
    MySublimeVideo.Helpers.VideoStatsChartsHelper.sparkline($last_60_minutes_loads,
      fillColor: 'rgba(74,100,142,0.3)'
      lineColor: '#596e8c')


MySublimeVideo.stats.drawPlaysAndLoadsGraph = ->
  if ($plays_and_loads = $('#plays_and_loads')).exists()
    MySublimeVideo.Helpers.VideoStatsChartsHelper.loadsAndStartsChart($plays_and_loads.data('plays'),
      $plays_and_loads.data('loads'),
      $plays_and_loads.data('hours'))

MySublimeVideo.stats.refreshTopStats = ->
  since = $('#last_plays li').first().data('time')
  $.ajax
    url: MySublimeVideo.Helpers.HistoryHelper.currentUrlWithNewQuery('since', since)
    dataType: 'script'

MySublimeVideo.stats.refreshBottomStats = ->
  $('#stats_dates_range_and_source_selector').submit()
  $('#stats_hours_select, #stats_source_select').prop('disabled', true)
  $('#plays_and_loads, #browsers_and_platforms .content_wrap, #countries .content_wrap, #mobile_desktop .content_wrap').spin()

MySublimeVideo.stats.prepareAutoSubmitForHoursSelect = ->
  $('#dates_range_and_source ul.actions a').on 'click', (event) ->
    $link = $(event.target)
    $ul = $link.parent('ul.actions')
    MySublimeVideo.stats.refreshBottomStats()
    MySublimeVideo.Helpers.HistoryHelper.updateQueryInUrl($ul.data('name'), $link.data('value'))

  false

MySublimeVideo.stats.prepareCSVExportButton = ->
  $('#csv_export').on 'click', (event) ->
    event.preventDefault()
    currentLocation = document.location
    csvLocation = "#{currentLocation.protocol}//#{currentLocation.hostname}#{currentLocation.pathname}.csv#{currentLocation.search}"
    window.open(csvLocation)

    false

class MySublimeVideo.Helpers.VideoStatsChartsHelper

  @sparkline: ($el, options = {}) ->
    $el.find('.sparkline').sparkline($el.data().sparklineData,
      width: '100%'
      height: '42px'
      lineColor: options.lineColor ? 'rgba(97,255,114,0.7)'
      fillColor: options.fillColor ? 'rgba(116,255,131,0.24)')

  @loadsAndStartsChart: (plays, loads, hours) ->
    Highcharts.setOptions
      global:
        useUTC: false

    new Highcharts.StockChart
      chart:
        renderTo: 'plays_and_loads_graph'
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
        data: plays
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
