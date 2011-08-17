MySublimeVideo.Views.Stats ||= {}

class MySublimeVideo.Views.Stats.ShowView extends Backbone.View
  template: JST["backbone/templates/stats/show"]
   
  render: ->
    $(this.el).html(this.template(this.options.model.toJSON() ))
    return this