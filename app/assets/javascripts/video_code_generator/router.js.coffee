class MSVVideoCodeGenerator.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    @loggedIn = options['logged_in']
    @sites    = options['sites']

    this.initModels()
    this.initViews()
    sublimevideo.load()

  initModels: ->
    MSVVideoCodeGenerator.sites = new MSV.Collections.Sites(@sites)

    MSVVideoCodeGenerator.builder = new MSVVideoCodeGenerator.Models.Builder

    MSVVideoCodeGenerator.loader = new MSVVideoCodeGenerator.Models.Loader(site: MSVVideoCodeGenerator.sites.at(0))

    MSVVideoCodeGenerator.demoPoster  = 'http://sublimevideo.net/assets/www/demo/midnight_sun_800.jpg'
    MSVVideoCodeGenerator.demoSources =
      mp4_base: 'http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.mp4'
      mp4_hd: 'http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.mp4'
      webmogg_base: 'http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.webm'
      webmogg_hd: 'http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.webm'
      # invalid sources for testing
      # mp4_base: 'http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.mp'
      # mp4_hd: 'ttp://media.jilion.com/videos/demo/midnight_sun_sv1_720p.mp4'
      # webmogg_base: 'http://sublimevideo.net/assets/www/demo/midnight_sun_800.jpg'
      # webmogg_hd: 'http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.webm'

    MSVVideoCodeGenerator.poster  = new MSVVideoCodeGenerator.Models.Image
    MSVVideoCodeGenerator.sources = new MSVVideoCodeGenerator.Collections.Sources([
      new MSVVideoCodeGenerator.Models.Source
      new MSVVideoCodeGenerator.Models.Source
        format: 'mp4', quality: 'hd', isUsed: false
      new MSVVideoCodeGenerator.Models.Source
        format: 'mp4', quality: 'mobile', isUsed: false
      new MSVVideoCodeGenerator.Models.Source
        format: 'webmogg', optional: true
      new MSVVideoCodeGenerator.Models.Source
        format: 'webmogg', optional: true, quality: 'hd', isUsed: false
    ])

    MSVVideoCodeGenerator.video = new MSVVideoCodeGenerator.Models.Video
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources

    # Lightbox specific models
    MSVVideoCodeGenerator.thumbnail = new MSVVideoCodeGenerator.Models.Thumbnail

    # Iframe embed specific models
    MSVVideoCodeGenerator.iframe = new MSVVideoCodeGenerator.Models.Iframe

  initViews: ->
    new MSVVideoCodeGenerator.Views.DemoBootstrap
      model: MSVVideoCodeGenerator.builder
      el: '#demo_bootstrap'

    new MSVVideoCodeGenerator.Views.VideoEmbedTypeSelector
      model: MSVVideoCodeGenerator.builder
      el: '#video_embed_type_selector'

    MSVVideoCodeGenerator.lightboxView = new MSVVideoCodeGenerator.Views.Lightbox
      thumbnail: MSVVideoCodeGenerator.thumbnail
      el: '#lightbox_attributes'

    MSVVideoCodeGenerator.iframeEmbedView = new MSVVideoCodeGenerator.Views.IframeEmbed
      model: MSVVideoCodeGenerator.iframe
      loader: MSVVideoCodeGenerator.loader
      sites: MSVVideoCodeGenerator.sites
      el: '#iframe_embed_attributes'

    MSVVideoCodeGenerator.posterView = new MSVVideoCodeGenerator.Views.Poster
      model: MSVVideoCodeGenerator.poster
      builder: MSVVideoCodeGenerator.builder
      el: '#poster'

    MSVVideoCodeGenerator.settingsView = new MSVVideoCodeGenerator.Views.Settings
      builder: MSVVideoCodeGenerator.builder
      collection: MSVVideoCodeGenerator.sources
      model: MSVVideoCodeGenerator.sources.mp4Base()
      el: '#settings'

    MSVVideoCodeGenerator.sourcesView = new MSVVideoCodeGenerator.Views.Sources
      collection: MSVVideoCodeGenerator.sources
      builder: MSVVideoCodeGenerator.builder
      video: MSVVideoCodeGenerator.video
      settingsView: MSVVideoCodeGenerator.settingsView
      el: '#sources'

    MSVVideoCodeGenerator.codeView = new MSVVideoCodeGenerator.Views.Code
      builder: MSVVideoCodeGenerator.builder
      loader: MSVVideoCodeGenerator.loader
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources
      thumbnail: MSVVideoCodeGenerator.thumbnail
      iframe: MSVVideoCodeGenerator.iframe
      sources: MSVVideoCodeGenerator.sources
      el: '#code'

    MSVVideoCodeGenerator.previewView = new MSVVideoCodeGenerator.Views.Preview
      builder: MSVVideoCodeGenerator.builder
      loader: MSVVideoCodeGenerator.loader
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources
      thumbnail: MSVVideoCodeGenerator.thumbnail
      iframe: MSVVideoCodeGenerator.iframe
      sources: MSVVideoCodeGenerator.sources
      el: '#preview'
