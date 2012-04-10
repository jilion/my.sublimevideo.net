class MSVVideoCodeGenerator.Models.Image extends MSVVideoCodeGenerator.Models.Asset
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
    new SublimeVideo.ImagePreloader(this.get('src'), this.setDimensions)

  setDimensions: (problem, imageSrc, dimensions) =>
    this.set(src: imageSrc) if imageSrc isnt this.get('src')
    if problem || !dimensions?
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')
      this.set(found: false) if problem
    else
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')
      this.set(found: true)

class MSVVideoCodeGenerator.Models.Thumbnail extends MSVVideoCodeGenerator.Models.Image
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

  setDimensions: (problem, imageSrc, dimensions) =>
    super(problem, imageSrc, dimensions)
    this.setThumbWidth(this.get('width'))

  setThumbWidth: (newThumbWidth) ->
    newThumbWidth = parseInt(newThumbWidth)
    newThumbWidth = 20 if _.isNaN(newThumbWidth) || newThumbWidth < 20
    newThumbWidth = 800 if newThumbWidth > 800

    this.set(thumbWidth: newThumbWidth)
    this.setThumbHeightWithRatio()
    this.trigger('change:thumbWidth')

  setThumbHeightWithRatio: ->
    this.set(thumbHeight: parseInt(this.get('thumbWidth') * this.get('ratio')))

  viewable: ->
    (this.get('initialLink') is 'text' and !this.srcIsEmpty()) or (this.get('initialLink') is 'image' and this.srcIsUsable())

  reset: ->
    super()
    this.set(initialLink: 'image')
    this.set(thumbWidth: null)
    this.set(thumbHeight: null)
