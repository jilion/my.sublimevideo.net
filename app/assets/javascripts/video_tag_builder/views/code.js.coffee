class MSVVideoTagBuilder.Views.Code extends Backbone.View
  template: JST['video_tag_builder/templates/_code']

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe
    @sources   = @options.sources

    _.bindAll this, 'render'
    @builder.bind   'change',     this.render
    @loader.bind    'change',     this.render
    @poster.bind    'change:src', this.render
    @thumbnail.bind 'change',     this.render
    @iframe.bind    'change:src', this.render
    @sources.bind   'change',     this.render

  #
  # BINDINGS
  #
  render: ->
    baseMp4 = @sources.mp4Base()
    attributes =
      poster: @poster
      sources: @sources
      width: baseMp4.get('embedWidth')
      height: baseMp4.get('embedHeight')

    switch MSVVideoTagBuilder.builder.get('builderClass')
      when 'lightbox'
        lightbox_attributes = { thumbnail: @thumbnail }
        attributes = $.extend({}, attributes, lightbox_attributes)
        MSVVideoTagBuilder.video = new MSVVideoTagBuilder.Models.VideoLightbox(attributes)
      when 'iframe_embed'
        MSVVideoTagBuilder.video = new MSVVideoTagBuilder.Models.VideoIframeEmbed(attributes)
      else
        MSVVideoTagBuilder.video = new MSVVideoTagBuilder.Models.Video(attributes)

    $(@el).html(this.template(video: MSVVideoTagBuilder.video))

    if baseMp4.srcIsUrl() && baseMp4.get('embedWidth')
      # $(MSVVideoTagBuilder.previewView.el).spin()
      MSVVideoTagBuilder.previewView.render()
    else
      MSVVideoTagBuilder.previewView.hide()

    this
