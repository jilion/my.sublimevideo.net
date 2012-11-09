class MSVVideoCodeGenerator.Models.Builder extends Backbone.Model
  defaults:
    builderClass: 'standard'
    startWithHd: false
    testAssetsUsed: false
    site: null
    kit: null
    currentStage: 'stable'

  sitesHostnamesMatchUrl: (site, url) ->
    hostnameMatch = this.hostnameRegex(site.get('hostname'), site.get('wildcard'), site.get('path')).test(url)
    extraHostnameMatch = site.get('extra_hostnames')? and _.find site.get('extra_hostnames').split(','), (hostname) =>
      this.hostnameRegex(hostname, site.get('wildcard'), site.get('path')).test(url)
    hostnameMatch or extraHostnameMatch

  hostnameRegex: (hostname, wildcard, path) ->
    ///https?:\/\/(#{if wildcard? then '.*' else 'www'}\.)?#{hostname.trim()}#{if path? then "\/#{path}(\/.*|$)" else '(\/.*$|$)'}///

  setTestAssets: ->
    MSVVideoCodeGenerator.poster = new MySublimeVideo.Models.Image
      src: MSVVideoCodeGenerator.testAssets['poster']
    sources = []
    _.each MSVVideoCodeGenerator.testAssets['sources'], (attributes) ->
      source = new MySublimeVideo.Models.Source(_.extend(attributes,
        currentMimeType: "video/#{attributes['format']}"))
      source.setDimensions(attributes['src'], { width: 640, height: 360 })
      source.setDefaultDataUID()
      sources.push source
    MSVVideoCodeGenerator.sources = new MySublimeVideo.Collections.Sources(sources)

    # Lightbox specific models
    MSVVideoCodeGenerator.thumbnail = new MySublimeVideo.Models.Thumbnail
      src: MSVVideoCodeGenerator.testAssets['thumbnail']

    this.set(testAssetsUsed: true)

  resetTestAssets: ->
    MSVVideoCodeGenerator.poster.reset()
    MSVVideoCodeGenerator.thumbnail.reset()
    _.each MSVVideoCodeGenerator.sources.models, (source) ->
      source.reset()

    this.set(testAssetsUsed: false)

class MSVVideoCodeGenerator.Models.Iframe extends MySublimeVideo.Models.Asset
  defaults:
    src: ''
    width: null
    height: null

class MSVVideoCodeGenerator.Models.Loader extends Backbone.Model
  defaults:
    site: null
    ssl: false
