class MySublimeVideo.UI.KitsPage
  constructor: ->
    this.setupModels()
    this.setupHelpers()

    sublimevideo.ready =>
      this.refreshVideoTagFromSettings()

  setupModels: ->
    thumbnail = new MySublimeVideo.Models.Thumbnail(initialLink: 'text', src: 'Test')
    poster  = new MySublimeVideo.Models.Image(src: '//dehqkotcrv4fy.cloudfront.net/images/midnight_sun_800.jpg')
    sources = new MySublimeVideo.Collections.Sources([
      new MySublimeVideo.Models.Source
        src: '//dehqkotcrv4fy.cloudfront.net/videos/demo/midnight_sun_sv1_1_360p.mp4'
      new MySublimeVideo.Models.Source
        format: 'webmogg'
        src: '//dehqkotcrv4fy.cloudfront.net/videos/demo/midnight_sun_sv1_1_360p.webm'
    ])

    @video = new MySublimeVideo.Models.Video
      thumbnail: thumbnail
      poster: poster
      sources: sources
      width: 368
      height: 207

  setupHelpers: ->
    @videoTagHelpers = {}
    $('li.kit').each (index, el) =>
      $li = $(el)
      @videoTagHelpers[$li.attr('id')] = new MySublimeVideo.Helpers.VideoTagHelper @video,
        settings: $li.data('settings')

  refreshVideoTagFromSettings: (type) ->
    $('li.kit').each (index, el) =>
      $li = $(el)
      liId = $li.attr('id')

      sublime.prepareWithKit("preview_#{liId}", $li.data('settings'))

