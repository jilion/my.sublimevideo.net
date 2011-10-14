class MSVVideoTagBuilder.Models.Image extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  setSrc: (src) ->
    this.set(src: src)
    this.preloadSrc()

  preloadSrc: ->
    new MSV.ImagePreloader(this.get('src'), this.setDimensions)

  setDimensions: (problem, imageSrc, dimensions) =>
    console.log(dimensions)
    unless problem
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(src: imageSrc) if imageSrc != this.get('src')
      this.set(width: newWidth) if newWidth != this.get('width')
      this.set(height: newHeight) if newHeight != this.get('height')
      this.set(ratio: newRatio) if newRatio != this.get('ratio')

class MSVVideoTagBuilder.Models.Thumbnail extends MSVVideoTagBuilder.Models.Image
  defaults:
    ratio: null
    thumbWidth: null
    thumbHeight: null
    magnifyingGlass: false

  setDimensions: (problem, imageSrc, dimensions) =>
    super(problem, imageSrc, dimensions)
    this.setThumbWidth(this.get('width'))

  setThumbWidth: (newThumbWidth) ->
    newThumbWidth = if _.isNumber(parseInt(newThumbWidth)) then parseInt(newThumbWidth) else 0
    if newThumbWidth != this.get('thumbWidth')
      this.set(thumbWidth: newThumbWidth)
      this.set(thumbHeight: parseInt(this.get('thumbWidth') * this.get('ratio')))
