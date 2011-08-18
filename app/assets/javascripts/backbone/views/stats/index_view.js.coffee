MySublimeVideo.Views.Stats ||= {}

class MySublimeVideo.Views.Stats.IndexView extends Backbone.View
  template: JST["backbone/templates/stats/index"]
    
  initialize: () ->
    _.bindAll(this, 'addOne', 'addAll', 'render');
    
    @options.stats.bind('reset', this.addAll);
   
  addAll: () ->
    @options.stats.each(this.addOne)
  
  addOne: (stat) ->
    view = new MySublimeVideo.Views.Stats.StatView({model : stat})
    this.$("tbody").append(view.render().el)
       
  render: ->
    $(this.el).html(this.template(stats: this.options.stats.toJSON() ))
    @addAll()
    
    return this