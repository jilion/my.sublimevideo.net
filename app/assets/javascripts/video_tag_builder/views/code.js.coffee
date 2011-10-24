class MSVVideoTagBuilder.Views.Code extends Backbone.View
  template: JST['video_tag_builder/templates/_code']
  warnings_template: JST['video_tag_builder/templates/code/_warnings']
  loader_template: JST['video_tag_builder/templates/code/_loader']
  video_tag_template: JST['video_tag_builder/templates/code/_video_tag']
  iframe_tag_template: JST['video_tag_builder/templates/code/_iframe_tag']
  iframe_content_template: JST['video_tag_builder/templates/code/_iframe_content']
  css_template: JST['video_tag_builder/templates/code/_css']

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe
    @sources   = @options.sources
    @video     = @options.video

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
    if @builder.get('useDemoAssets')
      poster  = MSVVideoTagBuilder.demoPoster
      sources = MSVVideoTagBuilder.demoSources
    else
      poster  = @poster
      sources = @sources
    $('input[type=text]').attr('disabled', @builder.get('useDemoAssets'))

    baseMp4 = sources.mp4Base()
    attributes =
      poster: poster
      sources: sources
      width: baseMp4.get('embedWidth')
      height: baseMp4.get('embedHeight')

    @video = switch @builder.get('builderClass')
      when 'lightbox'
        lightbox_attributes = { thumbnail: @thumbnail }
        attributes = $.extend({}, attributes, lightbox_attributes)
        new MSVVideoTagBuilder.Models.VideoLightbox(attributes)
      when 'iframe_embed'
        new MSVVideoTagBuilder.Models.VideoIframeEmbed(attributes)
      else
        new MSVVideoTagBuilder.Models.Video(attributes)
    MSVVideoTagBuilder.video = @video

    $(@el).html this.template
      builderClass: @builder.get('builderClass')
      loader: @loader
      video: @video
      warnings_block: => this.warnings_block()
      loader_block: => this.loader_block()
      video_embed_block: => this.video_embed_block()
      iframe_content_block: => this.iframe_content_block()
      css_block: => this.css_block()

    prettyPrint() # syntax highlighting

    if baseMp4.srcIsUrl() && baseMp4.get('embedWidth')
      # $(MSVVideoTagBuilder.previewView.el).spin()
      MSVVideoTagBuilder.previewView.render()
    else
      MSVVideoTagBuilder.previewView.hide()

    this

  #
  # HELPERS
  #
  warnings_block: ->
    this.warnings_template(video: @video)

  loader_block: ->
    this.loader_template
      builderClass: @builder.get('builderClass')
      loader: @loader
      video: @video

  video_embed_block: ->
    if @builder.get('builderClass') is 'iframe_embed'
      this.iframe_tag_template
        iframe: @iframe
        video: @video
    else
      this.video_tag_template
        builderClass: @builder.get('builderClass')
        video: @video

  iframe_content_block: ->
    this.iframe_content_template
      builderClass: @builder.get('builderClass')
      loader: @loader
      iframe: @iframe
      loader_content: this.loader_template
        builderClass: @builder.get('builderClass')
        loader: @loader
        video: @video
      video_content: this.video_tag_template
        builderClass: @builder.get('builderClass')
        video: @video

  css_block: ->
    this.css_template
      builderClass: @builder.get('builderClass')
      video: @video
