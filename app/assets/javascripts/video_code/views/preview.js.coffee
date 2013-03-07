class MSVVideoCode.Views.Preview extends Backbone.View
  template: JST['video_code/templates/preview']

  initialize: ->
    this._initUIHelpers()

    _.bindAll this, 'delayedRender'
    MSVVideoCode.kits.bind      'change',     this.delayedRender
    MSVVideoCode.video.bind     'change',     this.delayedRender
    MSVVideoCode.poster.bind    'change:src', this.delayedRender
    MSVVideoCode.sources.bind   'change',     this.delayedRender
    MSVVideoCode.thumbnail.bind 'change',     this.delayedRender

  # Ensure multiple sequential render are not possible
  #
  delayedRender: ->
    clearTimeout(@renderTimer) if @renderTimer
    @renderTimer = setTimeout((=> this.render()), 200)

  render: ->
    if MSVVideoCode.video.viewable() and (!MSVVideoCode.video.get('displayInLightbox') or MSVVideoCode.thumbnail.viewable())
      this._refreshPreview()
      $(@el).show()
    else
      $(@el).hide()

    this

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)

  _refreshPreview: ->
    @currentScroll = $(window).scrollTop()
    sublime.unprepare('video-preview') if $('#video-preview').exists()

    $(@el).html this.template(videoTagHelper: @videoTagHelper, settings: this._settings())

    sublime.prepare(if MSVVideoCode.video.get('displayInLightbox') then 'lightbox-trigger' else 'video-preview')

    $(window).scrollTop(@currentScroll)

  _settings: ->
    s = {}
    s['player'] = { 'kit': MSVVideoCode.kits.selected.get('identifier') } unless MSVVideoCode.kits.defaultKitSelected()

    _.extend(s, MSVVideoCode.kits.selected.get('settings'), MSVVideoCode.video.get('settings'))
