class MSVStats.Views.VVView extends Backbone.View
  template: JST['stats/templates/_vv_chart']

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);
    this.options.period.bind('change', this.render);

  render: ->
    vvData = this.collection.vvData()
    $(this.el).html(this.template(vvData: vvData))
    if this.collection.size() > 0
      a = 0
      Highcharts.setOptions
        global:
          useUTC: false
      new Highcharts.Chart
        chart:
          renderTo: 'vv_chart'
          backgroundColor: null
          plotBackgroundColor: null
          animation: false
          # plotBorderColor: 'black'
          # plotBorderWidth: 1
          # borderColor: 'black'
          # borderWidth: 1
          plotShadow: false
          marginTop: 10
          marginRight: 10
          marginBottom: 100
          marginLeft: 50
          spacingTop: 0
          spacingRight: 0
          spacingBottom: 0
          spacingLeft: 0
          height: 300
          width: 800
        colors: [
          '#edc950'
          '#65384a'
        ]
        credits:
          enabled: false
        title:
          text: null
        tooltip:
          crosshairs: true
          borderWidth: 0
          shadow: false
          shared: true
          formatter: ->
            title = ["<b>#{Highcharts.dateFormat('%e %B %Y, %H:%M', @x)} - #{Highcharts.dateFormat('%e %B %Y, %H:%M', @x + MSVStats.period.periodInterval())}</b><br/><br/>"]
            title += _.map(@points, (point) ->
              "<b>#{point.series.name}</b><br/>#{Highcharts.numberFormat(point.y, 0)} hits"
            ).join("<br/>")
        plotOptions:
          column:
            animation: false
            shadow: false
            borderWidth: 0
            showInLegend: false
            allowPointSelect: false
            stickyTracking: false
            lineWidth: 3
            # marker:
            #   enabled: false
            #   states:
            #     hover:
            #       enabled: true
            #       lineWidth: 5
            #       radius: 5
            #     select:
            #       enabled: false
            #       lineWidth: 5
            #       radius: 5
            dataLabels:
              enabled: false
            states:
              hover:
                enabled: false
                lineWidth: 3
                marker:
                  enabled: false
          spline:
            animation: false
            shadow: false
            borderWidth: 0
            showInLegend: false
            allowPointSelect: false
            stickyTracking: false
            lineWidth: 3
            marker:
              enabled: false
            dataLabels:
              enabled: false
            states:
              hover:
                enabled: false
                lineWidth: 3
                marker:
                  enabled: false
        series: [{
          type: MSVStats.period.periodChartType()
          name: 'Page visits'
          data: vvData.pv
          },{
          type: MSVStats.period.periodChartType()
          name: 'Video views'
          data: vvData.vv
        }]
        xAxis:
          lineWidth: 0
          # tickColor: 'black'
          # startOnTick: true
          # title:
          #   text: null
          tickInterval: MSVStats.period.periodTickInterval()
          # tickmarkPlacement: 'on'
          # tickPosition: ''
          # tickLength: 0
          tickWidth: 0
          # endOnTick: true
          gridLineWidth: 1
          type: 'datetime'
          # maxPadding: 0.001
          # endOnTick: false
        yAxis:
          # endOnTick: false
          # min: 0
          startOnTick: false
          title:
            text: null
          # tickmarkPlacement: 'on'
          # tickPosition: 'inside'
          # tickLength: 300
          # tickWidth: 1
          # tickInterval: 3
          # maxPadding: 0.2
          # minPadding: 0.2

        # legend:
        #   layout: 'vertical'
        #   margin: 0
        #   align: 'right'
        #   verticalAlign: 'middle'
        #   x: 15
        #   y: -5
        #   lineHeight: 20
        #   borderWidth: 0
        #   width: 200
          # labelFormatter: ->
          #   '<b>' + @name + '</b>: ' + @y + 'hits'
    return this
