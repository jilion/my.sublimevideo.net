describe 'Image and Thumbnail', ->

  describe 'MySublimeVideo.Models.Image', ->
    beforeEach ->
      @image = new MySublimeVideo.Models.Image

    describe 'setAndPreloadSrc()', ->
      it 'sets the src', ->
        @image.setAndPreloadSrc('http://sublimevideo.net/demo/dartmoor.jpg')
        expect(@image.get('src')).toEqual('http://sublimevideo.net/demo/dartmoor.jpg')

      it 'sets the width, height and ratio', ->
        @image.setAndPreloadSrc('http://sublimevideo.net/demo/dartmoor.jpg')
        @image.bind 'change:ratio', ->
          expect(@image.get('width')).toEqual(800)
          expect(@image.get('height')).toEqual(350)
          expect(@image.get('ratio')).toEqual(350 / 800)

    describe 'setDimensions()', ->
      it 'sets the width, height and ratio', ->
        @image.setDimensions(false, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:800, height:350 })
        expect(@image.get('width')).toEqual(800)
        expect(@image.get('height')).toEqual(350)
        expect(@image.get('ratio')).toEqual(350 / 800)

      it 'an error occured, doens\'t set the width, height nor ratio', ->
        @image.setDimensions(true, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:800, height:350 })
        expect(@image.get('width')).toEqual(0)
        expect(@image.get('height')).toEqual(0)
        expect(@image.get('ratio')).toEqual(1)

  describe 'MySublimeVideo.Models.Thumbnail', ->
    beforeEach ->
      @thumb = new MySublimeVideo.Models.Thumbnail

    describe 'setDimensions()', ->
      it 'sets the width, height and ratio', ->
        @thumb.setDimensions(false, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:800, height:350 })
        expect(@thumb.get('width')).toEqual(800)
        expect(@thumb.get('height')).toEqual(350)
        expect(@thumb.get('ratio')).toEqual(350 / 800)
        expect(@thumb.get('thumbWidth')).toEqual(800)
        expect(@thumb.get('thumbHeight')).toEqual(350)

      it 'an error occured, doens\'t set the width, height nor ratio', ->
        @thumb.setDimensions(true, 'http://sublimevideo.net/demo/dartmoor.jpg', { width:800, height:350 })
        expect(@thumb.get('width')).toEqual(0)
        expect(@thumb.get('height')).toEqual(0)
        expect(@thumb.get('ratio')).toEqual(1)
        expect(@thumb.get('thumbWidth')).toEqual(20)
        expect(@thumb.get('thumbHeight')).toEqual(20)

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

      it 'maximum is 800', ->
        @thumb.setThumbWidth(5000)
        expect(@thumb.get('thumbWidth')).toEqual(800)

    describe 'setThumbHeightWithRatio()', ->
      it 'sets thumbHeight from thumbWidth and ratio', ->
        @thumb.set(thumbWidth:300, ratio:0.5)
        @thumb.setThumbHeightWithRatio()
        expect(@thumb.get('thumbHeight')).toEqual(150)

    describe 'viewable()', ->
      it 'returns false if initialLink is text and src is empty', ->
        @thumb.set(initialLink: 'text')
        @thumb.set(src: '')

        expect(@thumb.viewable()).toBeFalsy()

      it 'returns true if initialLink is text and src is not empty', ->
        @thumb.set(initialLink: 'text')
        @thumb.set(src: 'foo')

        expect(@thumb.viewable()).toBeTruthy()

      it 'returns false if initialLink is image and src is empty', ->
        @thumb.set(initialLink: 'image')
        @thumb.set(src: '')

        expect(@thumb.viewable()).toBeFalsy()

      it 'returns false if initialLink is image and src is not a url', ->
        @thumb.set(initialLink: 'image')
        @thumb.set(src: 'foo')

        expect(@thumb.viewable()).toBeFalsy()

      it 'returns false if initialLink is image and src is not found', ->
        @thumb.set(initialLink: 'image')
        @thumb.set(src: 'http://foo.com/test.jpg')
        @thumb.set(found: false)

        expect(@thumb.viewable()).toBeFalsy()

      it 'returns false if initialLink is image and src is found', ->
        @thumb.set(initialLink: 'image')
        @thumb.set(src: 'http://foo.com/test.jpg')
        @thumb.set(found: true)

        expect(@thumb.viewable()).toBeTruthy()

    describe 'reset()', ->
      it 'resets the initialLink, thumbWidth and thumbHeight attributes', ->
        @thumb.set(initialLink: 'text')
        @thumb.set(thumbWidth: 12)
        @thumb.set(thumbHeight: 42)

        expect(@thumb.get('initialLink')).toEqual('text')
        expect(@thumb.get('thumbWidth')).toEqual(12)
        expect(@thumb.get('thumbHeight')).toEqual(42)

        @thumb.reset()

        expect(@thumb.get('initialLink')).toEqual('image')
        expect(@thumb.get('thumbWidth')).toEqual(null)
        expect(@thumb.get('thumbHeight')).toEqual(null)
