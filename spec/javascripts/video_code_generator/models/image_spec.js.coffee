describe 'Image and Thumbnail', ->

  describe 'MSVVideoCodeGenerator.Models.Image', ->
    beforeEach ->
      @image = new MSVVideoCodeGenerator.Models.Image

    describe 'setAndPreloadSrc()', ->
      it 'sets the src', ->
        @image.setAndPreloadSrc('http://sublimevideo.net/demo/dartmoor.jpg')
        expect(@image.get('src')).toEqual('http://sublimevideo.net/demo/dartmoor.jpg')

      it 'sets the width, height and ratio', ->
        @image.setAndPreloadSrc('http://sublimevideo.net/demo/dartmoor.jpg')
        @image.bind 'change:ratio', ->
          expect(@image.get('width')).toEqual(858)
          expect(@image.get('height')).toEqual(364)
          expect(@image.get('ratio')).toEqual(364 / 858)

    describe 'setDimensions()', ->
      it 'sets the width, height and ratio', ->
        @image.setDimensions(false, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:858, height:364 })
        expect(@image.get('width')).toEqual(858)
        expect(@image.get('height')).toEqual(364)
        expect(@image.get('ratio')).toEqual(364 / 858)

      it 'an error occured, doens\'t set the width, height nor ratio', ->
        @image.setDimensions(true, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:858, height:364 })
        expect(@image.get('width')).toEqual(0)
        expect(@image.get('height')).toEqual(0)
        expect(@image.get('ratio')).toEqual(0)

  describe 'MSVVideoCodeGenerator.Models.Thumbnail', ->
    beforeEach ->
      @thumb = new MSVVideoCodeGenerator.Models.Thumbnail

    describe 'setDimensions()', ->
      it 'sets the width, height and ratio', ->
        @thumb.setDimensions(false, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:858, height:364 })
        expect(@thumb.get('width')).toEqual(858)
        expect(@thumb.get('height')).toEqual(364)
        expect(@thumb.get('ratio')).toEqual(364 / 858)
        expect(@thumb.get('thumbWidth')).toEqual(858)
        expect(@thumb.get('thumbHeight')).toEqual(364)

      it 'an error occured, doens\'t set the width, height nor ratio', ->
        @thumb.setDimensions(true, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:858, height:364 })
        expect(@thumb.get('width')).toEqual(0)
        expect(@thumb.get('height')).toEqual(0)
        expect(@thumb.get('ratio')).toEqual(0)
        expect(@thumb.get('thumbWidth')).toEqual(20)
        expect(@thumb.get('thumbHeight')).toEqual(0)

    describe 'setThumbWidth()', ->
      beforeEach ->
        @thumb.set(ratio: 0.5)

      it 'sets thumbWidth to 0 if it is not a number', ->
        @thumb.setThumbWidth('a')
        expect(@thumb.get('thumbWidth')).toEqual(20)

      it 'cast the given width to integer', ->
        @thumb.setThumbWidth('200')
        expect(@thumb.get('thumbWidth')).toEqual(200)

      it 'sets the given width casted to integer', ->
        @thumb.setThumbWidth(200.4)
        expect(@thumb.get('thumbWidth')).toEqual(200)

      it 'minimum is 20', ->
        @thumb.setThumbWidth(5)
        expect(@thumb.get('thumbWidth')).toEqual(20)

      it 'maximum is 2000', ->
        @thumb.setThumbWidth(5000)
        expect(@thumb.get('thumbWidth')).toEqual(2000)

    describe 'setThumbHeightWithRatio()', ->
      it 'sets thumbHeight from thumbWidth and ratio', ->
        @thumb.set(thumbWidth:300, ratio:0.5)
        @thumb.setThumbHeightWithRatio()
        expect(@thumb.get('thumbHeight')).toEqual(150)
