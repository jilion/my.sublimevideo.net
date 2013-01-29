class MySublimeVideo.Models.Video extends Backbone.Model
  defaults:
    origin: 'files'
    youTubeId: null
    displayInLightbox: false
    startWithHd: false
    poster: null
    sources: null
    sourceWidth: 640
    sourceHeight: 360
    ratio: 360 / 640
    width: 640
    height: 360
    keepRatio: true
    autoresize: 'none'
    autoplay: false
    settings: {}

  viewable: ->
    if this.get('youTubeId')?
      true
    else
      result = false
      _.each this.get('sources').allUsedNotEmpty(), (source) ->
        if source.srcIsUsable()
          result = true
          return
      result

  setYouTubeId: (newYouTubeId) ->
    if matches = newYouTubeId.match(/(youtube\.com\/.+v=|youtu\.be\/)(\w+)(&|$)/)
      newYouTubeId = matches[2]

    this.set(youTubeId: newYouTubeId)

  setKeepRatio: (newKeepRatio) ->
    this.set(keepRatio: newKeepRatio)
    this.setHeightWithRatio() if this.get('keepRatio')

  setWidth: (newWidth) ->
    newWidth = parseInt(newWidth, 10)
    newWidth = 200 if _.isNaN(newWidth) or newWidth < 200

    this.set(width: _.min([newWidth, 852]))
    this.setHeightWithRatio() if this.get('keepRatio')
    this.trigger('change:width')

  setHeight: (newHeight) ->
    newHeight = parseInt(newHeight, 10)
    newHeight = 100 if _.isNaN(newHeight) or newHeight < 100

    this.set(height: _.min([newHeight, 720]))
    this.setWidthWithRatio() if this.get('keepRatio')
    this.trigger('change:height')

  setHeightWithRatio: ->
    this.set(height: parseInt(this.get('width') * this.get('ratio'), 10))

  setWidthWithRatio: ->
    this.set(width: parseInt(this.get('height') / this.get('ratio'), 10))

  setDefaultDataUID: ->
    mp4BaseSrc = this.get('sources').mp4Base().get('src')
    this.set(dataUID: crc32(mp4BaseSrc)) unless !mp4BaseSrc

  clearDataUIDAndName: ->
    this.set(dataUID: '')
    this.set(dataName: '')

  updateSetting: (addon, setting, value) ->
    this.get('settings')[addon] = {} unless this.get('settings')[addon]?
    this.get('settings')[addon][setting] = {} unless this.get('settings')[addon][setting]?

    this.get('settings')[addon][setting] = value
    this.trigger('change')
