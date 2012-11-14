class MySublimeVideo.UI.KitsPage
  constructor: ->
    this.setupModels()
    this.setupHelpers()

    sublimevideo.ready =>
      this.refreshVideoTagFromSettings()

  setupModels: ->
    thumbnail = new MySublimeVideo.Models.Thumbnail(initialLink: 'text', src: 'Test')
    poster  = new MySublimeVideo.Models.Image(src: '//media.jilion.com/images/midnight_sun_800.jpg')
    sources = new MySublimeVideo.Collections.Sources([
      new MySublimeVideo.Models.Source
        src: '//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.mp4'
      new MySublimeVideo.Models.Source
        format: 'webmogg'
        src: '//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.webm'
    ])

    @video = new MySublimeVideo.Models.Video
      thumbnail: thumbnail
      poster: poster
      sources: sources
      width: 320
      height: 180

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

      videoCode = @videoTagHelpers[liId].generateVideoCode(id: "preview_kit_#{liId}")
      $("#preview_#{liId}").replaceWith(videoCode)
      sublimevideo.prepare("preview_kit_#{liId}")
