MySublimeVideo.videoStatsReady = ->
  MySublimeVideo.prepareAutoSubmitForHoursSelect()

MySublimeVideo.prepareAutoSubmitForHoursSelect = ->
  $('#video_stats_hours_select, #video_stats_source_select').on 'change', (event) ->
    $(event.target).parent('form').submit()
    $('#vv, #bp, #co').spin()

class MySublimeVideo.Helpers.VideoStatsChartsHelper

  @sparkline: (el, serie, options = {}) ->
    el.sparkline serie,
      width: options.width
      height: options.height
      lineColor: options.lineColor ? (if options.selected then '#00ff18' else 'rgba(97,255,114,0.7)')
      fillColor: options.fillColor ? (if options.selected then 'rgba(116,255,131,0.46)' else 'rgba(116,255,131,0.24)')

  @loadsAndStartsChart: (loads, starts, hours) ->
    new Highcharts.Chart
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
        name: 'Page visits'
        data: loads
        shadow: false
        fillColor: 'rgba(74,100,142,0.3)'
        color: '#596e8c'
        lineColor: '#596e8c'
        marker:
          enabled: false # (hours <= 24)
        },{
        type: 'areaspline'
        name: 'Video plays'
        data: starts
        shadow:
          color: 'rgb(116, 255, 131)'
          offsetX: 1e-100
          offsetY: 1e-100
          opacity: 0.22
          width: 6
        fillColor: 'rgba(9,250,33,0.15)'
        color: '#00ff18'
        lineColor: '#00ff18'
        marker:
          enabled: false # (hours <= 24)
          symbol: "url(<%= asset_path 'stats/graph_dot.png' %>)"
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
          align: 'right'
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
        height: 250
        width: 250
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
          "<span style=\"color:#a2b1c9;font-weight:normal\">#{@point.name}</span> #{Highcharts.numberFormat(@point.y, 0)} hits"
      scrollbar:
        enabled: false
      plotOptions:
        pie:
          dataLabels:
            enabled: false
      series: [{
        type: 'pie'
        name: 'Mobile / Desktop'
        data: data
        shadow: false
        fillColor: 'rgba(74,100,142,0.3)'
        color: '#596e8c'
      }]
