describe 'Image and Thumbnail', ->
  
  describe 'MSVVideoTagBuilder.Models.Image', ->
    beforeEach ->
      @image = new MSVVideoTagBuilder.Models.Image

    describe 'srcIsUrl()', ->
      it 'returns false when not an URL', ->
        @image.set(src: 'test')
        expect(@image.srcIsUrl()).toBeFalsy()

      it 'returns true when an URL', ->
        @image.set(src: 'http://test.com')
        expect(@image.srcIsUrl()).toBeTruthy()

  describe 'MSVVideoTagBuilder.Models.Thumbnail', ->
    beforeEach ->
      @thumb = new MSVVideoTagBuilder.Models.Thumbnail

    describe 'setThumbWidth()', ->
      it 'sets thumbWidth to 0 if it is not a number', ->
        @thumb.setThumbWidth('a')
        expect(@thumb.get('thumbWidth')).toEqual(0)

      it 'cast the given width to integer', ->
        @thumb.setThumbWidth('2')
        expect(@thumb.get('thumbWidth')).toEqual(2)

      it 'sets the given width casted to integer', ->
        @thumb.setThumbWidth(2.4)
        expect(@thumb.get('thumbWidth')).toEqual(2)
