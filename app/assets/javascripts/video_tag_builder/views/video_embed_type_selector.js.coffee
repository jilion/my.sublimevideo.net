class MSVVideoTagBuilder.Views.VideoEmbedTypeSelector extends Backbone.View

  events:
    'click input': 'updateBuilderClass'

  initialize: ->
    _.bindAll this, 'render', 'renderSpecializedBox'
    @model.bind 'change:builderClass', this.renderSpecializedBox

  #
  # EVENTS
  #
  updateBuilderClass: (event) ->
    @model.set({ builderClass: event.target.id.replace('type_', '') })

  #
  # BINDINGS
  #
  renderSpecializedBox: ->
    $(".specialized_video_embed_type_box").hide()

    switch @model.get('builderClass')
      when 'lightbox'     then MSVVideoTagBuilder.lightboxView.render()
      when 'iframe_embed' then MSVVideoTagBuilder.iframeEmbedView.render()
      when 'standard'
        MSVVideoTagBuilder.lightboxView.hide()
        MSVVideoTagBuilder.iframeEmbedView.hide()
