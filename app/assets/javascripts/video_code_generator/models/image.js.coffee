class MSVVideoCodeGenerator.Models.Image extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null
    validSrc: true

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  setAndPreloadSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)
      this.preloadSrc()

  preloadSrc: ->
    new SublimeVideo.ImagePreloader(this.get('src'), this.setDimensions)

  setDimensions: (problem, imageSrc, dimensions) =>
    this.set(src: imageSrc) if imageSrc isnt this.get('src')
    if problem || !dimensions?
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')
      this.set(validSrc: false)
    else
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')
      this.set(validSrc: true)

class MSVVideoCodeGenerator.Models.Thumbnail extends MSVVideoCodeGenerator.Models.Image
  defaults:
    initialLink: 'image'
    src: ""
    width: null
    height: null
    validSrc: true
    ratio: null
    thumbWidth: null
    thumbHeight: null
    magnifyingGlass: false

  setDimensions: (problem, imageSrc, dimensions) =>
    super(problem, imageSrc, dimensions)
    this.setThumbWidth(this.get('width'))

  setThumbWidth: (newThumbWidth) ->
    newThumbWidth = parseInt(newThumbWidth)
    newThumbWidth = 20 if _.isNaN(newThumbWidth) || newThumbWidth < 20
    newThumbWidth = 2000 if newThumbWidth > 2000

    if newThumbWidth isnt this.get('thumbWidth')
      this.set(thumbWidth: newThumbWidth)
      this.setThumbHeightWithRatio()

  setThumbHeightWithRatio: ->
    this.set(thumbHeight: parseInt(this.get('thumbWidth') * this.get('ratio')))
