class MSVVideoCode.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    @sites                = options['sites']
    @selectedSiteToken    = options['selectedSiteToken']
    @kits                 = options['kits']
    @defaultKitIdentifier = options['defaultKitIdentifier']

    this.initModels()
    this.initViews()
    new MySublimeVideo.UI.DependantInputs

    sublime.load()
    sublime.ready =>
      MSVVideoCode.previewView.render()

  initModels: ->
    MSVVideoCode.sites = new MySublimeVideo.Collections.Sites(@sites)
    MSVVideoCode.sites.select @selectedSiteToken

    MSVVideoCode.kits = new MySublimeVideo.Collections.Kits(@kits)
    MSVVideoCode.kits.setDefaultKit(@defaultKitIdentifier)
    MSVVideoCode.kits.select @defaultKitIdentifier

    MSVVideoCode.video     = new MySublimeVideo.Models.Video
    MSVVideoCode.poster    = new MySublimeVideo.Models.Image
    MSVVideoCode.sources   = new MySublimeVideo.Collections.Sources
    MSVVideoCode.thumbnail = new MySublimeVideo.Models.Thumbnail

    MSVVideoCode.playerModels = [MSVVideoCode.kits, MSVVideoCode.video, MSVVideoCode.poster, MSVVideoCode.sources, MSVVideoCode.thumbnail]

    this.setTestAssets()

  setTestAssets: ->
    MSVVideoCode.poster.setDimensions(false, MSVVideoCode.testAssets['poster'], { width: 800, height: 450 })
    sources = []
    _.each MSVVideoCode.testAssets['sources'], (attributes) =>
      source = new MySublimeVideo.Models.Source(_.extend(attributes,
        currentMimeType: "video/#{attributes['format']}"
        video: MSVVideoCode.video))
      source.setDimensions(attributes['src'], { sourceWidth: 640, sourceHeight: 360, width: 640, height: 360, ratio: 360 / 640 })
      sources.push source
    MSVVideoCode.sources.reset(sources, silent: true)

    # Lightbox specific models
    MSVVideoCode.thumbnail.setDimensions(false, MSVVideoCode.testAssets['thumbnail'], { width: 192, height: 108 })

    MSVVideoCode.video.set
      origin: 'test'
      poster: MSVVideoCode.poster
      sources: MSVVideoCode.sources
      thumbnail: MSVVideoCode.thumbnail
      title: 'Midnight Sun'

    MSVVideoCode.video.setDefaultDataUID()

  clearAssets: ->
    MSVVideoCode.poster.reset()
    MSVVideoCode.thumbnail.reset()
    _.each MSVVideoCode.sources.models, (source) ->
      source.reset()
    MSVVideoCode.video.clearUidAndTitle()

  initViews: ->
    MSVVideoCode.previewView = new MSVVideoCode.Views.Preview
      el: '#preview'

    MSVVideoCode.kitView = new MSVVideoCode.Views.Kit
      el: '#kit_selection'

    MSVVideoCode.sourcesView = new MSVVideoCode.Views.Sources
      el: '#video_sources_fields'

    MSVVideoCode.settingsView = new MSVVideoCode.Views.Settings
      el: '#video_settings_fields'

    MSVVideoCode.lightboxView = new MSVVideoCode.Views.Lightbox
      el: '#lightbox_settings_fields'

    MSVVideoCode.sharingView = new MSVVideoCode.Views.Sharing
      el: '#sharing_settings_fields'

    MSVVideoCode.embedView = new MSVVideoCode.Views.Embed
      el: '#embed_settings_fields'

    MSVVideoCode.codeView = if $('#video_code_form').data('assistant')
      new MSVVideoCode.Views.AssistantCode
    else if $('.get_the_code').exists()
      new MSVVideoCode.Views.Code
        el: '#video_code_form'
