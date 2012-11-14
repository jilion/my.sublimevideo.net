describe 'MySublimeVideo.Models.Video', ->
  beforeEach ->
    @video = new MySublimeVideo.Models.Video

  describe 'setKeepRatio()', ->
    it 'recalculate only height from width and ratio when keepRatio is set to true', ->
      @video.set(width: 500)
      @video.set(height: 250)
      @video.set(ratio: 0.5)

      @video.setWidth(500)
      expect(@video.get('width')).toEqual(500)
      expect(@video.get('height')).toEqual(250)

      @video.set(keepRatio: false)
      @video.set(height: 100)
      expect(@video.get('width')).toEqual(500)
      expect(@video.get('height')).toEqual(100)

      @video.setKeepRatio(true)
      expect(@video.get('width')).toEqual(500)
      expect(@video.get('height')).toEqual(250)

    it 'don\'t recalculate anything when keepRatio is set to false', ->
      @video.set(width: 500)
      @video.set(height: 250)
      @video.set(ratio: 0.5)

      @video.setWidth(250)
      expect(@video.get('width')).toEqual(250)
      expect(@video.get('height')).toEqual(125)

      @video.setKeepRatio(false)
      expect(@video.get('width')).toEqual(250)
      expect(@video.get('height')).toEqual(125)

  describe 'setWidth()', ->
    it 'sets width to 200 if it is not a number', ->
      @video.setWidth('a')
      expect(@video.get('width')).toEqual(200)

    it 'cast the given width to integer', ->
      @video.setWidth('250')
      expect(@video.get('width')).toEqual(250)

    it 'sets the given width casted to integer', ->
      @video.setWidth(250.4)
      expect(@video.get('width')).toEqual(250)

    it 'minimum is 200', ->
      @video.setWidth(50)
      expect(@video.get('width')).toEqual(200)

    it 'maximum is 852', ->
      @video.setWidth(5000)
      expect(@video.get('width')).toEqual(852)

  describe 'setHeight()', ->
    it 'sets height to 100 if it is not a number', ->
      @video.setHeight('a')
      expect(@video.get('height')).toEqual(100)

    it 'cast the given height to integer', ->
      @video.setHeight('250')
      expect(@video.get('height')).toEqual(250)

    it 'sets the given height casted to integer', ->
      @video.setHeight(250.4)
      expect(@video.get('height')).toEqual(250)

    it 'minimum is 100', ->
      @video.setHeight(50)
      expect(@video.get('height')).toEqual(100)

    it 'maximum is 720', ->
      @video.setHeight(9999)
      expect(@video.get('height')).toEqual(720)

  describe 'setHeightWithRatio()', ->
    it 'sets height from width and ratio', ->
      @video.set(width:300, ratio:0.5)
      @video.setHeightWithRatio()
      expect(@video.get('height')).toEqual(150)

  describe 'setWidthWithRatio()', ->
    it 'sets width from height and ratio', ->
      @video.set(height:300, ratio:0.5)
      @video.setWidthWithRatio()
      expect(@video.get('width')).toEqual(600)
