class MSVVideoCodeGenerator.Views.Code extends Backbone.View
  template: JST['video_code_generator/templates/_code']
  loaderTemplate: JST['video_code_generator/templates/code/_loader']
  videoTagTemplate: JST['video_code_generator/templates/code/_video_tag']
  iframeTagTemplate: JST['video_code_generator/templates/code/_iframe_tag']
  iframeContentTemplate: JST['video_code_generator/templates/code/_iframe_content']
  cssTemplate: JST['video_code_generator/templates/code/_css']

  events:
    'click #get_the_code': 'render'

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @sources   = @options.sources
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe

    @popup = new MSV.SimplePopupHandler("popup_code")

  #
  # BINDINGS
  #
  render: ->
    $("#code_content").html this.template
      builder: @builder
      loader: @loader
      iframe: @iframe
      video: @model
      loaderTemplate: this.loaderTemplate
      embedTemplate: this.embedTemplate()
      iframeTagTemplate: this.iframeTagTemplate
      videoTagTemplate: this.videoTagTemplate
      iframeContentTemplate: this.iframeContentTemplate
      cssTemplate: this.cssTemplate

    @popup.open()

    this

  #
  # HELPERS
  #
  embedTemplate: ->
    if @builder.get('builderClass') is 'iframe_embed'
      this.iframeTagTemplate
    else
      this.videoTagTemplate

  hide: ->
    @popup.close()
