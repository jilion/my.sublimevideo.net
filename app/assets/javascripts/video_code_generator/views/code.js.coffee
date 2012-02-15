class MSVVideoCodeGenerator.Views.Code extends Backbone.View
  template: JST['video_code_generator/templates/_code']
  warningsTemplate: JST['video_code_generator/templates/code/_warnings']
  loaderTemplate: JST['video_code_generator/templates/code/_loader']
  videoTagTemplate: JST['video_code_generator/templates/code/_video_tag']
  iframeTagTemplate: JST['video_code_generator/templates/code/_iframe_tag']
  iframeContentTemplate: JST['video_code_generator/templates/code/_iframe_content']
  cssTemplate: JST['video_code_generator/templates/code/_css']

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe

    _.bindAll this, 'render'
    @builder.bind   'change:builderClass',     this.render
    @builder.bind   'change:startWithHd',     this.render
    @loader.bind    'change',     this.render
    @poster.bind    'change:src', this.render
    @thumbnail.bind 'change',     this.render
    @iframe.bind    'change:src', this.render
    MSVVideoCodeGenerator.sources.bind   'change',     this.render

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template
      builderClass: @builder.get('builderClass')
      loader: @loader
      video: MSVVideoCodeGenerator.video
      warningsTemplate: this.warningsTemplate()
      # warnings_block: => this.warnings_block()
      loader_block: => this.loader_block()
      video_embed_block: => this.video_embed_block()
      iframe_content_block: => this.iframe_content_block()
      css_block: => this.css_block()

    prettyPrint() # syntax highlighting

    baseMp4 = MSVVideoCodeGenerator.sources.mp4Base()
    if baseMp4.srcIsUrl() && baseMp4.get('embedWidth')
      # $(MSVVideoCodeGenerator.previewView.el).spin()
      MSVVideoCodeGenerator.previewView.render()
    else
      MSVVideoCodeGenerator.previewView.hide()

    this

  #
  # HELPERS
  #
  warnings_block: ->
    this.warningsTemplate(video: MSVVideoCodeGenerator.video)

  loader_block: ->
    this.loaderTemplate
      builderClass: @builder.get('builderClass')
      loader: @loader
      video: MSVVideoCodeGenerator.video

  video_embed_block: ->
    if @builder.get('builderClass') is 'iframe_embed'
      this.iframeTagTemplate
        iframe: @iframe
        video: MSVVideoCodeGenerator.video
    else
      this.videoTagTemplate
        builderClass: @builder.get('builderClass')
        video: MSVVideoCodeGenerator.video

  iframe_content_block: ->
    this.iframeContentTemplate
      builderClass: @builder.get('builderClass')
      loader: @loader
      iframe: @iframe
      loader_content: this.loaderTemplate
        builderClass: @builder.get('builderClass')
        loader: @loader
        video: MSVVideoCodeGenerator.video
      video_content: this.videoTagTemplate
        builderClass: @builder.get('builderClass')
        video: MSVVideoCodeGenerator.video

  css_block: ->
    this.cssTemplate
      builderClass: @builder.get('builderClass')
      video: MSVVideoCodeGenerator.video
