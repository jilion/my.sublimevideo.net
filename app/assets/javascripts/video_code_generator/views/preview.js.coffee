class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/_preview']

  initialize: ->
    _.bindAll this, 'delayedRender'
    MSVVideoCodeGenerator.video.bind     'change',       this.delayedRender
    # MSVVideoCodeGenerator.video.bind     'change:origin',       this.delayedRender
    # MSVVideoCodeGenerator.video.bind     'change:youtubeId',    this.delayedRender
    MSVVideoCodeGenerator.poster.bind    'change:src',          this.delayedRender
    MSVVideoCodeGenerator.sources.bind   'change',              this.delayedRender
    MSVVideoCodeGenerator.thumbnail.bind 'change',              this.delayedRender

  # Ensure multiple sequential render are not possible
  #
  delayedRender: ->
    clearTimeout(@renderTimer) if @renderTimer
    @renderTimer = setTimeout((=> this.render()), 200)

  render: ->
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCodeGenerator.video,
      lightbox: MSVVideoCodeGenerator.video.get('displayInLightbox')
      startWithHd: MSVVideoCodeGenerator.video.get('startWithHd')
    )
    console.log 'preview!'
    if MSVVideoCodeGenerator.video.viewable() and (!MSVVideoCodeGenerator.video.get('displayInLightbox') or MSVVideoCodeGenerator.thumbnail.viewable())
      @currentScroll = $(window).scrollTop()
      $video = $('video')

      sublimevideo.unprepare($video[0]) if $video.exists()
      $(@el).html this.template
        video: MSVVideoCodeGenerator.video
        posterSrc: MSVVideoCodeGenerator.poster.get('src')
        video: MSVVideoCodeGenerator.video
        videoTagHelper: @videoTagHelper

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
