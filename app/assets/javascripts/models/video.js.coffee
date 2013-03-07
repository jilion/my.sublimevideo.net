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

  setUid: (newUid) ->
    if /^[a-z0-9_\-]{0,64}$/i.test(newUid)
      this.set(uid: newUid)
    else
      false

  setKeepRatio: (newKeepRatio) ->
    this.set(keepRatio: newKeepRatio)
    this._setHeightFromWidth() if this.get('keepRatio')

  setWidth: (newWidth, updateHeight = true) ->
    newWidth = parseInt(newWidth, 10)
    newWidth = 200 if _.isNaN(newWidth) or newWidth < 200

    if newWidth isnt this.get('width')
      this.set(width: _.min([newWidth, 1920]))
      if this.get('keepRatio') and updateHeight
        this._setHeightFromWidth()

  setHeight: (newHeight, updateWidth = true) ->
    newHeight = parseInt(newHeight, 10)
    newHeight = 100 if _.isNaN(newHeight) or newHeight < 100

    if newHeight isnt this.get('height')
      this.set(height: _.min([newHeight, 1080]))
      if this.get('keepRatio') and updateWidth
        this._setWidthFromHeight()

  setDefaultDataUID: ->
    mp4BaseSrc = this.get('sources').mp4Base().get('src')
    this.setUid(crc32(mp4BaseSrc)) if mp4BaseSrc?

  clearUidAndTitle: ->
    this.set(uid: '')
    this.set(title: '')

  updateSetting: (addonName, settingName, value, selectedKit) ->
    this.get('settings')[addonName] ?= {}
    this.get('settings')[addonName][settingName] ?= {}

    if selectedKit.getSetting(addonName, settingName) is value
      delete this.get('settings')[addonName][settingName]
    else
      this.get('settings')[addonName][settingName] = value
    this.trigger('change')

  getSetting: (addonName, settingName, selectedKit) ->
    if addonSettings = this.get('settings')[addonName]
      if setting = addonSettings[settingName]
        return setting

    selectedKit.getSetting(addonName, settingName)

  _setHeightFromWidth: ->
    this.setHeight(parseInt(this.get('width') * this.get('ratio'), 10), false)

  _setWidthFromHeight: ->
    this.setWidth(parseInt(this.get('height') / this.get('ratio'), 10), false)
