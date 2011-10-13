class MSVVideoTagBuilder.Views.Sources extends Backbone.View
  template: JST['video_tag_builder/templates/_sources']

  events:
    'keyup .source': 'updateSrc'
    'change .source': 'updateSrc'

  initialize: ->
    _.bindAll this, 'render'
    # @model.bind 'change:src', this.preloadSrc

  updateSrc: (event) ->
    @model.set(src: event.target.value)

  render: ->
    $(@el).html(this.template(collection: @collection))

    this