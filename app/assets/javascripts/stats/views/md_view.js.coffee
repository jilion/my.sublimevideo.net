class MSVStats.Views.MDView extends Backbone.View

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);
    this.options.period.bind('change', this.render);

  render: ->
    if MSVStats.stats.size() > 0
      console.log MSVStats.stats.mdData().m

      new Highcharts.Chart
        chart:
          renderTo: 'md_pie_chart'
          backgroundColor: null
          plotBackgroundColor: null
          # plotBorderColor: 'black'
          # plotBorderWidth: 1
          # borderColor: 'black'
          # borderWidth: 1
          plotShadow: false
          # margin: [0, 0, 0, 0]
          marginTop: 0
          marginRight: 200
          marginBottom: 0
          marginLeft: 0
          spacingTop: 0
          spacingRight: 0
          spacingBottom: 0
          spacingLeft: 0
          height: 200
          width: 400
        credits:
          enabled: false
        title:
          text: null
        tooltip:
          formatter: ->
            "<b>#{@point.name}</b><br/> #{Highcharts.numberFormat(@y, 0)} hits (#{Highcharts.numberFormat(@percentage, 1)} %)"
        plotOptions:
          pie:
            animation: true
            showInLegend: true
            allowPointSelect: false
            dataLabels:
              enabled: false
        series: [{
          type: 'pie'
          name: 'Player Mode'
          size: '85%'
          innerSize: '45%'
          data: MSVStats.stats.mdData().toArray('m')
          },{
          type: 'pie'
          name: 'Device'
          size: '45%'
          data: MSVStats.stats.mdData().toArray('d')
        }]
        legend:
          layout: 'vertical'
          margin: 0
          align: 'right'
          verticalAlign: 'middle'
          x: 15
          y: -5
          lineHeight: 20
          borderWidth: 0
          width: 200
          # labelFormatter: ->
          #   '<b>' + @name + '</b>: ' + @y + 'hits'
    return this
