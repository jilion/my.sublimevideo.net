class MSVVideoTagBuilder.Models.Image extends Backbone.Model
  defaults:
    src: ""
    width: null
    height: null

  srcIsUrl: ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test this.get('src')

  preloadSrc: =>
    new MSV.ImagePreloader(this.get('src'), this.setDimensions)

  setDimensions: (problem, imageSrc, dimensions) =>
    if problem
      console.log('problem!')
    else
      newWidth  = parseInt(dimensions[0])
      newHeight = parseInt(dimensions[1])
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
    this.updateDimensionsWithWidth(this.get('width'))

  updateDimensionsWithWidth: (width) ->
    width = parseInt(width)
    if width != this.get('thumbWidth')
      this.set(thumbWidth: width)
      this.set(thumbHeight: parseInt(this.get('thumbWidth') * this.get('ratio')))
