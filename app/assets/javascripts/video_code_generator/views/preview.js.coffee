class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/_preview']

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @sources   = @options.sources
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe

    _.bindAll this, 'delayedRender'
    @builder.bind   'change:builderClass', this.delayedRender
    @builder.bind   'change:startWithHd',  this.delayedRender
    @poster.bind    'change:src',          this.delayedRender
    @sources.bind   'change',              this.delayedRender
    @thumbnail.bind 'change',              this.delayedRender

  # Ensure multiple sequential render are not possible
  #
  delayedRender: ->
    clearTimeout(@renderTimer) if @renderTimer
    @renderTimer = setTimeout((=> this.render()), 200)

  render: ->
    if MSVVideoCodeGenerator.video.viewable() and (@builder.get('builderClass') isnt 'lightbox' or MSVVideoCodeGenerator.thumbnail.viewable())
      @currentScroll = $(window).scrollTop()
      $video = $('video')

      sublimevideo.unprepare($video) if $video.exists()
      $(@el).html this.template
        builder: @builder
        posterSrc: MSVVideoCodeGenerator.video.get('poster').get('src')
        video: MSVVideoCodeGenerator.video

      $video = $('video')
      sublimevideo.ready ->
        sublimevideo.prepare($video) if $video.exists()

      $(@el).show()
      $(window).scrollTop(@currentScroll)

    else
      this.hide()

    this

  hide: ->
    $(@el).hide()
