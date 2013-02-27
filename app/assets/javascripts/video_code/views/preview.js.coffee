class MSVVideoCode.Views.Preview extends Backbone.View
  template: JST['video_code/templates/preview']

  initialize: ->
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)

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
      this.refreshPreview()
      $(@el).show()
    else
      $(@el).hide()

    this

  refreshPreview: ->
    @currentScroll = $(window).scrollTop()

    sublime.unprepare('video-preview') if $('#video-preview').exists()
    kitSettings = MSVVideoCode.kits.selected.get('settings')
    settings = {}
    settings = this.combineKitAndVideoSettings()
    settings['player'] = { 'kit': MSVVideoCode.kits.selected.get('identifier') } unless MSVVideoCode.kits.defaultKitSelected()

    $(@el).html this.template(video: MSVVideoCode.video, videoTagHelper: @videoTagHelper, settings: settings)

    sublime.prepare(if MSVVideoCode.video.get('displayInLightbox') then 'lightbox-trigger' else 'video-preview')

    $(window).scrollTop(@currentScroll)

  combineKitAndVideoSettings: ->
    s = {}
    _.defaults(s, MSVVideoCode.kits.selected.get('settings'))
    _.each MSVVideoCode.video.get('settings'), (addonSettings, addonName) ->
      if s[addonName]?
        _.extend(s[addonName], addonSettings)
      else
        s[addonName] = addonSettings

    s
