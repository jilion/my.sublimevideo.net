class MSVVideoTagBuilder.Views.VideoEmbedTypeSelector extends Backbone.View

  events:
    'click a': 'updateBuilderClass'

  initialize: ->
    _.bindAll this, 'render', 'renderSpecializedBox'
    @model.bind 'change:builderClass', this.renderSpecializedBox

  #
  # EVENTS
  #
  updateBuilderClass: (event) ->
    @model.set({ builderClass: event.target.id })
    event.stopPropagation()
    false

  #
  # BINDINGS
  #
  renderSpecializedBox: ->
    this.$("li").removeClass('active')
    this.$(event.target).parent('li').addClass('active')

    $(".specialized_video_embed_type_box").hide()

    switch @model.get('builderClass')
      when 'lightbox'     then MSVVideoTagBuilder.lightboxView.render()
      when 'iframe_embed' then MSVVideoTagBuilder.iframeEmbedView.render()
      when 'standard'
        MSVVideoTagBuilder.lightboxView.remove()
        MSVVideoTagBuilder.iframeEmbedView.remove()
