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
      builder: @builder
      loader: @loader
      iframe: @iframe
      video: MSVVideoCodeGenerator.video
      warningsTemplate: this.warningsTemplate
      loaderTemplate: this.loaderTemplate
      embedTemplate: this.embedTemplate()
      iframeContentTemplate: this.iframeContentTemplate
      cssTemplate: this.cssTemplate

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
  embedTemplate: ->
    if @builder.get('builderClass') is 'iframe_embed'
      this.iframeTagTemplate
    else
      this.videoTagTemplate
