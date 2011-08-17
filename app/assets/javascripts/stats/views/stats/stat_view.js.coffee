MySublimeVideo.Views.Stats ||= {}

class MySublimeVideo.Views.Stats.StatView extends Backbone.View
  template: JST["backbone/templates/stats/stat"]
  
  events:
    "click .destroy" : "destroy"
      
  tagName: "tr"
  
  destroy: () ->
    @options.model.destroy()
    this.remove()
    
    return false
    
  render: ->
    $(this.el).html(this.template(this.options.model.toJSON() ))    
    return this