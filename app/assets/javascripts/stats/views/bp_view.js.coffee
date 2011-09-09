class MSVStats.Views.BPView extends Backbone.View
  template: JST['stats/templates/_bp_pie_chart']

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);
    this.options.period.bind('change', this.render);

  render: ->
    @bpData = this.collection.bpData()
    $(this.el).html(this.template(bpData: @bpData))
    
    $('#bp_content').show()
    $('#bp').data().spinner.stop()

    this.renderChart()
    return this

  renderChart: ->
    new Highcharts.Chart
      chart:
        renderTo: 'bp_pie_chart'
        backgroundColor: null
        plotBackgroundColor: null
        plotShadow: false
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
      colors: [
      	'#edc950'
      	'#65384a'
      	'#eb6840'
      	'#06a0b0'
      	'#cc343e'
      ]
      credits:
        enabled: false
      title:
        text: null
      tooltip:
        formatter: ->
          "<b>#{@point.name}</b><br/> #{Highcharts.numberFormat(@y, 0)} hits (#{Highcharts.numberFormat(@percentage, 1)} %)"
      plotOptions:
        pie:
          shadow: false
          borderWidth: 0
          animation: false
          showInLegend: true
          size: '85%'
          allowPointSelect: false
          dataLabels:
            enabled: false
      series: [
        type: 'pie'
        name: 'Browser + OS'
        data: @bpData.toArray()
      ]
      legend:
        layout: 'vertical'
        margin: 0
        align: 'right'
        verticalAlign: 'middle'
        x: 15
        y: -5
        lineHeight: 17
        borderWidth: 0
        width: 200
