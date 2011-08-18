class MySublimeVideo.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    @stats = new MySublimeVideo.Collections.StatsCollection()
    @stats.reset options.stats

  routes:
    "/new": "newStat"
    "/index": "index"
    "/:id/edit": "edit"
    "/:id": "show"
    ".*": "index"

  newStat: ->
    @view = new MySublimeVideo.Views.Stats.NewView(collection: @stats)
    $("#stats").html(@view.render().el)

  index: ->
    @view = new MySublimeVideo.Views.Stats.IndexView(stats: @stats)
    $("#stats").html(@view.render().el)

  show: (id) ->
    stat = @stats.get(id)
    
    @view = new MySublimeVideo.Views.Stats.ShowView(model: stat)
    $("#stats").html(@view.render().el)
    
  edit: (id) ->
    stat = @stats.get(id)

    @view = new MySublimeVideo.Views.Stats.EditView(model: stat)
    $("#stats").html(@view.render().el)
  