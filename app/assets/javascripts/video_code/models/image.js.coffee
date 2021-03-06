class MySublimeVideo.Models.Image extends MySublimeVideo.Models.Asset
  defaults:
    found: true
    ratio: 1

  setAndPreloadSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)

      if this.srcIsEmpty()
        this.reset()
      else if this.srcIsUrl()
        this.preloadSrc()
      else
        this.set(found: false)

  preloadSrc: ->
    new SublimeVideo.Media.ImagePreloader(this.get('src'), this.setDimensions)

  setDimensions: (problem, imageSrc, dimensions) ->
    this.set(src: imageSrc) if imageSrc isnt this.get('src')
    if problem || !dimensions?
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')
      this.set(found: false) if problem
    else
      newWidth  = parseInt(dimensions['width'], 10)
      newHeight = parseInt(dimensions['height'], 10)
      newRatio  = newHeight / newWidth

      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')
      this.set(found: true)

class MySublimeVideo.Models.Thumbnail extends MySublimeVideo.Models.Image
  defaults:
    initialLink: 'image'
    thumbWidth: null
    thumbHeight: null
    found: true
    ratio: 1

  setAndPreloadSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)

      if this.srcIsEmpty()
        this.reset()
      else if this.srcIsUrl()
        this.preloadSrc()
      else
        this.set(found: false)

  setDimensions: (problem, imageSrc, dimensions) ->
    super(problem, imageSrc, dimensions)
    this.setThumbWidth(this.get('width'))

  setThumbWidth: (newThumbWidth, updateThumbHeight = true) ->
    newThumbWidth = parseInt(newThumbWidth, 10)
    newThumbWidth = 20 if _.isNaN(newThumbWidth) || newThumbWidth < 20

    if newThumbWidth isnt this.get('thumbWidth')
      this.set(thumbWidth: _.min([newThumbWidth, 800]))
      if updateThumbHeight
        this._setThumbHeightFromWidth()

  setThumbHeight: (newThumbHeight, updateThumbWidth = true) ->
    newThumbHeight = parseInt(newThumbHeight, 10)
    newThumbHeight = 20 if _.isNaN(newThumbHeight) || newThumbHeight < 20

    if newThumbHeight isnt this.get('thumbHeight')
      this.set(thumbHeight: _.min([newThumbHeight, 400]))
      if updateThumbWidth
        this._setThumbWidthFromHeight()

  viewable: ->
    (this.get('initialLink') is 'text' and !this.srcIsEmpty()) or (this.get('initialLink') is 'image' and this.srcIsUsable())

  reset: ->
    super()
    this.set(initialLink: 'image')
    this.set(thumbWidth: null)
    this.set(thumbHeight: null)

  _setThumbHeightFromWidth: ->
    this.setThumbHeight(parseInt(this.get('thumbWidth') * this.get('ratio'), 10), false)

  _setThumbWidthFromHeight: ->
    this.setThumbWidth(parseInt(this.get('thumbHeight') / this.get('ratio'), 10), false)
