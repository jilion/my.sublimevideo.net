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
      kitId = switch $li.data('design')
        when 'classic' then '1'
        when 'flat'    then '2'
        when 'light'   then '3'

      console.log "preview_#{liId}"
      console.log _.extend(@videoTagHelpers[liId].generateDataSettings(), { 'player-kit': kitId })

      sublime.reprepareVideo("preview_#{liId}", _.extend(@videoTagHelpers[liId].generateDataSettings(), { 'player-kit': kitId }))
      $li.find('.preview').show()

