class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/_preview']

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
    @poster.bind    'change:src',          this.render
    @sources.bind   'change',              this.render
    @thumbnail.bind 'change',              this.render

  #
  # BINDINGS
  #
  render: ->
    MSVVideoCodeGenerator.codeView.hide()
    if MSVVideoCodeGenerator.video.viewable() and (@builder.get('builderClass') isnt 'lightbox' or MSVVideoCodeGenerator.thumbnail.get('initialLink') is 'text' or MSVVideoCodeGenerator.thumbnail.srcIsUrl())
      currentScroll = $(window).scrollTop()
      $(@el).hide()

      sublimevideo.unprepare($('video').get(0)) if $('video').length

      $(@el).html this.template
        builder: @builder
        posterSrc: MSVVideoCodeGenerator.video.get('poster').get('src')
        video: MSVVideoCodeGenerator.video

      sublimevideo.prepare($('video').get(0)) if $('video').length

      $(@el).show()
      $(window).scrollTop(currentScroll)
    else
      this.hide()

    this

  hide: ->
    $(@el).hide()

  videoPreviewable: ->
    result = false
    @sources.each (source) ->
      if source.srcIsUsable()
        result = true
        return
    result
