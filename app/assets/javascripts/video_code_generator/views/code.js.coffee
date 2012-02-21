class MSVVideoCodeGenerator.Views.Code extends Backbone.View
  template: JST['video_code_generator/templates/_code']
  warningsTemplate: JST['video_code_generator/templates/code/_warnings']
  loaderTemplate: JST['video_code_generator/templates/code/_loader']
  videoTagTemplate: JST['video_code_generator/templates/code/_video_tag']
  iframeTagTemplate: JST['video_code_generator/templates/code/_iframe_tag']
  iframeContentTemplate: JST['video_code_generator/templates/code/_iframe_content']
  cssTemplate: JST['video_code_generator/templates/code/_css']

  events:
    'click #get_the_code': 'show'

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @sources   = @options.sources
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe
    @showCode  = false

    this.render()

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template
      showCode: @showCode
      builder: @builder
      loader: @loader
      iframe: @iframe
      video: MSVVideoCodeGenerator.video
      warningsTemplate: this.warningsTemplate
      loaderTemplate: this.loaderTemplate
      embedTemplate: this.embedTemplate()
      iframeTagTemplate: this.iframeTagTemplate
      videoTagTemplate: this.videoTagTemplate
      iframeContentTemplate: this.iframeContentTemplate
      cssTemplate: this.cssTemplate

    prettyPrint() # syntax highlighting

    this

  #
  # HELPERS
  #
  embedTemplate: ->
    if @builder.get('builderClass') is 'iframe_embed'
      this.iframeTagTemplate
    else
      this.videoTagTemplate

  show: ->
    @showCode = true
    this.render()

  hide: ->
    @showCode = false
    this.render()
