class MSVVideoCodeGenerator.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    @userSignedIn      = options['userSignedIn']
    @sites             = options['sites']
    @selectedSiteToken = options['selectedSiteToken']
    @kit               = options['kit']
    @currentStage      = options['currentStage']

    this.handlePublicClass()
    this.initModels()
    this.initViews()
    sublimevideo.load()
    MSVVideoCodeGenerator.previewView.render()

  handlePublicClass: ->
    $('body').addClass('mysv_public') unless @userSignedIn

  initModels: ->
    MSVVideoCodeGenerator.sites = new MySublimeVideo.Collections.Sites(@sites)
    MSVVideoCodeGenerator.sites.select @selectedSiteToken

    MSVVideoCodeGenerator.builder = new MSVVideoCodeGenerator.Models.Builder
      site: MSVVideoCodeGenerator.sites.selectedSite
      kit: @kit
      currentStage : @currentStage
      testAssetsUsed: true

    MSVVideoCodeGenerator.loader = new MSVVideoCodeGenerator.Models.Loader(site: MSVVideoCodeGenerator.sites.at(0))
    MSVVideoCodeGenerator.loader.set(site: MSVVideoCodeGenerator.sites.selectedSite)

    MSVVideoCodeGenerator.builder.setTestAssets()

    # Iframe embed specific models
    MSVVideoCodeGenerator.iframe = new MSVVideoCodeGenerator.Models.Iframe

    MSVVideoCodeGenerator.video = new MySublimeVideo.Models.Video
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources
    MSVVideoCodeGenerator.video.get('sources').mp4Base().set(dataName: 'Midnight Sun')

  initViews: ->
    # new MSVVideoCodeGenerator.Views.DemoBootstrap
    #   model: MSVVideoCodeGenerator.builder
    #   el: '#demo_bootstrap'

    new MSVVideoCodeGenerator.Views.VideoEmbedTypeSelector
      model: MSVVideoCodeGenerator.builder
      el: '#video_embed_type_selector'

    MSVVideoCodeGenerator.lightboxView = new MSVVideoCodeGenerator.Views.Lightbox
      builder:   MSVVideoCodeGenerator.builder
      thumbnail: MSVVideoCodeGenerator.thumbnail
      el: '#lightbox_attributes'

    MSVVideoCodeGenerator.iframeEmbedView = new MSVVideoCodeGenerator.Views.IframeEmbed
      model:   MSVVideoCodeGenerator.iframe
      builder: MSVVideoCodeGenerator.builder
      loader:  MSVVideoCodeGenerator.loader
      sites:   MSVVideoCodeGenerator.sites
      el: '#iframe_embed_attributes'

    MSVVideoCodeGenerator.posterView = new MSVVideoCodeGenerator.Views.Poster
      builder: MSVVideoCodeGenerator.builder
      model:   MSVVideoCodeGenerator.poster
      el: '#poster'

    MSVVideoCodeGenerator.settingsView = new MSVVideoCodeGenerator.Views.Settings
      builder:    MSVVideoCodeGenerator.builder
      collection: MSVVideoCodeGenerator.sources
      model:      MSVVideoCodeGenerator.video
      el: '#settings'

    if $('#kit_settings_form').exists()
      $.get "/sites/#{@selectedSiteToken}/players/#{@kit['id']}.js"

    MSVVideoCodeGenerator.sourcesView = new MSVVideoCodeGenerator.Views.Sources
      collection: MSVVideoCodeGenerator.sources
      builder: MSVVideoCodeGenerator.builder
      video: MSVVideoCodeGenerator.video
      settingsView: MSVVideoCodeGenerator.settingsView
      el: '#video_sources'

    MSVVideoCodeGenerator.codeView = new MSVVideoCodeGenerator.Views.Code
      builder: MSVVideoCodeGenerator.builder
      loader: MSVVideoCodeGenerator.loader
      poster: MSVVideoCodeGenerator.poster
      thumbnail: MSVVideoCodeGenerator.thumbnail
      iframe: MSVVideoCodeGenerator.iframe
      sources: MSVVideoCodeGenerator.sources
      el: '#code'

    MSVVideoCodeGenerator.previewView = new MSVVideoCodeGenerator.Views.Preview
      builder: MSVVideoCodeGenerator.builder
      video: MSVVideoCodeGenerator.video
      loader: MSVVideoCodeGenerator.loader
      poster: MSVVideoCodeGenerator.poster
      thumbnail: MSVVideoCodeGenerator.thumbnail
      iframe: MSVVideoCodeGenerator.iframe
      sources: MSVVideoCodeGenerator.sources
      el: '#preview'
