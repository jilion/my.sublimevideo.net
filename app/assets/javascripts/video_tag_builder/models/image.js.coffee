class MSVVideoTagBuilder.Models.Image extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  setAndPreloadSrc: (src) ->
    unless src is this.get('src')
      this.set(src: src)
      this.preloadSrc() if this.srcIsUrl()

  preloadSrc: ->
    new MSV.ImagePreloader(this.get('src'), this.setDimensions)

  setDimensions: (problem, imageSrc, dimensions) =>
    this.set(src: imageSrc) if imageSrc isnt this.get('src')
    if problem || !dimensions?
      this.set(width: 0)  unless this.get('width')
      this.set(height: 0) unless this.get('height')
      this.set(ratio: 0)  unless this.get('ratio')
    else
      newWidth  = parseInt(dimensions['width'])
      newHeight = parseInt(dimensions['height'])
      newRatio  = newHeight / newWidth

      this.set(width: newWidth)   unless newWidth  is this.get('width')
      this.set(height: newHeight) unless newHeight is this.get('height')
      this.set(ratio: newRatio)   unless newRatio  is this.get('ratio')

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
    newThumbWidth = parseInt(newThumbWidth)
    newThumbWidth = 20 if !_.isNumber(newThumbWidth) || newThumbWidth < 20
    newThumbWidth = 2000 if newThumbWidth > 2000

    if newThumbWidth isnt this.get('thumbWidth')
      this.set(thumbWidth: newThumbWidth)
      this.setThumbHeightWithRatio()

  setThumbHeightWithRatio: ->
    this.set(thumbHeight: parseInt(this.get('thumbWidth') * this.get('ratio')))
