class SVStats.Models.Stat extends Backbone.Model
  time: -> parseInt(this.id) * 1000
  date: -> new Date(this.time())

class SVStats.Collections.Stats extends Backbone.Collection
  initialize: -> @selected = ['active']
  chartType: (selected) -> 'spline'
  yAxis: (selected) -> 0
  startTime: -> this.at(0).time()
