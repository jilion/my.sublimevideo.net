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

  setDataUID: (newDataUID) ->
    if /^[a-z0-9_\-]{0,64}$/i.test(newDataUID)
      this.set(dataUID: newDataUID)
    else
      false

  setKeepRatio: (newKeepRatio) ->
    this.set(keepRatio: newKeepRatio)
    this._setHeightFromWidth() if this.get('keepRatio')

  setWidth: (newWidth, updateHeight = true) ->
    newWidth = parseInt(newWidth, 10)
    console.log newWidth
    newWidth = 200 if _.isNaN(newWidth) or newWidth < 200

    if newWidth isnt this.get('width')
      this.set(width: _.min([newWidth, 852]))
      this._setHeightFromWidth() if this.get('keepRatio') and updateHeight
      this.trigger('change:width')

  setHeight: (newHeight, updateHeight = true) ->
    newHeight = parseInt(newHeight, 10)
    newHeight = 100 if _.isNaN(newHeight) or newHeight < 100

    if newHeight isnt this.get('height')
      this.set(height: _.min([newHeight, 720]))
      this._setWidthFromHeight() if this.get('keepRatio') and updateHeight
      this.trigger('change:height')

  setDefaultDataUID: ->
    mp4BaseSrc = this.get('sources').mp4Base().get('src')
    this.setDataUID(crc32(mp4BaseSrc)) unless !mp4BaseSrc

  clearDataUIDAndName: ->
    this.set(dataUID: '')
    this.set(dataName: '')

  updateSetting: (addon, setting, value) ->
    this.get('settings')[addon] = {} unless this.get('settings')[addon]?
    this.get('settings')[addon][setting] = {} unless this.get('settings')[addon][setting]?

    this.get('settings')[addon][setting] = value
    this.trigger('change')

  getSetting: (addonName, settingName, kitForDefault) ->
    if addonSettings = this.get('settings')[addonName]
      if setting = addonSettings[settingName]
        return setting

    kitForDefault.getSetting(addonName, settingName)

  _setWidthFromHeight: ->
    this.setWidth(parseInt(this.get('height') / this.get('ratio'), 10), false)

  _setHeightFromWidth: ->
    this.setHeight(parseInt(this.get('width') * this.get('ratio'), 10), false)
