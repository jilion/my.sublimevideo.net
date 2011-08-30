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
      new Highcharts.Chart
        chart:
          renderTo: 'vv_chart'
          backgroundColor: null
          plotBackgroundColor: null
          # plotBorderColor: 'black'
          # plotBorderWidth: 1
          # borderColor: 'black'
          # borderWidth: 1
          plotShadow: false
          marginTop: 20
          marginRight: 20
          marginBottom: 20
          marginLeft: 100
          spacingTop: 0
          spacingRight: 0
          spacingBottom: 0
          spacingLeft: 0
          height: 200
          width: 650
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
            _.map(@points, (point) -> 
              "<b>#{point.series.name}<br/> #{Highcharts.numberFormat(point.y, 0)} hits"
            ).join("<br/>")
        plotOptions:
          spline:
            shadow: false
            borderWidth: 0
            animation: false
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
            zIndex: 10
        series: [{
          type: 'spline'
          name: 'Page visits'
          data: vvData.pv
          },{
          type: 'spline'
          name: 'Video views'
          data: vvData.vv
        }]
        # xAxis:
        #   # offset: 20
        #   # lineWidth: 0
        yAxis:
          # endOnTick: false
          # min: 0
          startOnTick: false
          title:
            text: null
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
