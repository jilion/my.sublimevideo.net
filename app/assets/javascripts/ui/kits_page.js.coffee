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
      new MySublimeVideo.Models.Source().setAndPreloadSrc('//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.mp4')
      new MySublimeVideo.Models.Source(format: 'webmogg').setAndPreloadSrc('//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.webm')
    ])

    @video = new MySublimeVideo.Models.Video
      thumbnail: thumbnail
      poster: poster
      sources: sources

  setupHelpers: ->
    @videoTagHelpers = {}
    $('li.kit').each (index, el) =>
      $li = $(el)
      @videoTagHelpers[$li.attr('id')] = new MySublimeVideo.Helpers.VideoTagHelper @video,
        type: 'standard',
        settings: $li.data('settings')

  refreshVideoTagFromSettings: (type) ->
    $('li.kit').each (index, el) =>
      $li = $(el)

      videoCode = @videoTagHelpers[$li.attr('id')].generateVideoCode(id: "preview_kit_#{$li.attr('id')}")

      $("#preview_#{$li.attr('id')}").replaceWith(videoCode)
      sublimevideo.prepare("preview_kit_#{$li.attr('id')}")
