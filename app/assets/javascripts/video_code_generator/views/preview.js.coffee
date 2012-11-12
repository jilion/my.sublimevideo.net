class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/_preview']

  initialize: ->
    @builder   = @options.builder
    @video     = @options.video
    @loader    = @options.loader
    @poster    = @options.poster
    @sources   = @options.sources
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe

    _.bindAll this, 'delayedRender'
    @builder.bind   'change:builderClass', this.delayedRender
    @builder.bind   'change:startWithHd',  this.delayedRender
    @video.bind     'change:origin',       this.delayedRender
    @video.bind     'change:youtubeId',    this.delayedRender
    @poster.bind    'change:src',          this.delayedRender
    @sources.bind   'change',              this.delayedRender
    @thumbnail.bind 'change',              this.delayedRender

  # Ensure multiple sequential render are not possible
  #
  delayedRender: ->
    clearTimeout(@renderTimer) if @renderTimer
    @renderTimer = setTimeout((=> this.render()), 200)

  render: ->
    if @video.viewable() and (@builder.get('builderClass') isnt 'lightbox' or MSVVideoCodeGenerator.thumbnail.viewable())
      @currentScroll = $(window).scrollTop()
      $video = $('video')

      sublimevideo.unprepare($video[0]) if $video.exists()
      $(@el).html this.template
        builder: @builder
        video: @video
        posterSrc: @video.get('poster').get('src')
        video: @video

      $video = $('video')
      sublimevideo.ready ->
        sublimevideo.prepare($video[0]) if $video.exists()

      $(@el).show()
      $(window).scrollTop(@currentScroll)

    else
      this.hide()

    this

  hide: ->
    $(@el).hide()
