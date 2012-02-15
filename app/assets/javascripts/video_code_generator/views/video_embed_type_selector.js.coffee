class MSVVideoCodeGenerator.Views.VideoEmbedTypeSelector extends Backbone.View

  events:
    'click input': 'updateBuilderClass'

  initialize: ->
    _.bindAll this, 'renderSpecializedBox'
    @model.bind 'change:builderClass', this.renderSpecializedBox

  #
  # EVENTS
  #
  updateBuilderClass: (event) ->
    newBuilderClass = event.target.id.replace('type_', '')

    baseMp4 = MSVVideoCodeGenerator.sources.mp4Base()
    attributes =
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources
      width: baseMp4.get('embedWidth')
      height: baseMp4.get('embedHeight')

    MSVVideoCodeGenerator.video = switch newBuilderClass
      when 'lightbox'
        attributes = $.extend({}, attributes, { thumbnail: MSVVideoCodeGenerator.thumbnail })
        new MSVVideoCodeGenerator.Models.VideoLightbox(attributes)
      when 'iframe_embed'
        new MSVVideoCodeGenerator.Models.VideoIframeEmbed(attributes)
      else
        new MSVVideoCodeGenerator.Models.Video(attributes)

    @model.set(builderClass: newBuilderClass)

  #
  # BINDINGS
  #
  renderSpecializedBox: ->
    $(".specialized_video_embed_type_box").hide()

    switch @model.get('builderClass')
      when 'lightbox'     then MSVVideoCodeGenerator.lightboxView.render()
      when 'iframe_embed' then MSVVideoCodeGenerator.iframeEmbedView.render()
      when 'standard'
        MSVVideoCodeGenerator.lightboxView.hide()
        MSVVideoCodeGenerator.iframeEmbedView.hide()
