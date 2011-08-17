class MySublimeVideo.Models.Stat extends Backbone.Model
  paramRoot: 'stat'

  defaults:
    title: null
    content: null
  
class MySublimeVideo.Collections.StatsCollection extends Backbone.Collection
  model: MySublimeVideo.Models.Stat
  url: '/stats'