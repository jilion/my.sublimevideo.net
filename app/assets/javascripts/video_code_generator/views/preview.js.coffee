class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/_preview']
  iframe_template: JST['video_code_generator/templates/_preview_iframe']

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @sources   = @options.sources
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe

    _.bindAll this, 'render'
    @builder.bind   'change:builderClass', this.render
    @builder.bind   'change:startWithHd',  this.render
    @loader.bind    'change',              this.render
    @poster.bind    'change:src',          this.render
    @sources.bind   'change',              this.render
    @thumbnail.bind 'change',              this.render
    @iframe.bind    'change:src',          this.render
    # MSVVideoCodeGenerator.sources.bind 'change',     this.render

  #
  # BINDINGS
  #
  render: ->
    MSVVideoCodeGenerator.codeView.hide()
    $(@el).spin()
    baseMp4 = @sources.mp4Base()
    if baseMp4.srcIsUrl() && baseMp4.get('embedWidth')
      currentScroll = $(window).scrollTop()
      $(@el).hide()

      sublimevideo.unprepare($('video').get(0)) if $('video').length

      $(@el).html (if @builder.get('builderClass') is 'iframe_embed' then this.iframe_template else this.template)
        builder: @builder
        posterSrc: MSVVideoCodeGenerator.video.get('poster').get('src')
        video: MSVVideoCodeGenerator.video
        sortedSources: MSVVideoCodeGenerator.video.get('sources').sortedSources(@builder.get('startWithHd'))

      sublimevideo.prepare($('video').get(0)) if $('video').length

      $(@el).data().spinner.stop()
      $(@el).show()
      $(window).scrollTop(currentScroll)
    else
      MSVVideoCodeGenerator.previewView.hide()

    this

  hide: ->
    $(@el).hide()
